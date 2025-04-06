import XCTest
import Combine
@testable import Nos

final class PushNotificationPreferenceTests: CoreDataTestCase {
    var pushNotificationService: PushNotificationService!
    var currentUser: Author!
    var follower: Author!
    var followOfFollower: Author!
    var randomPerson: Author!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        pushNotificationService = PushNotificationService()
        
        // Create test users
        currentUser = Author(context: viewContext)
        currentUser.hexadecimalPublicKey = KeyFixture.alice.publicKey.hex
        
        follower = Author(context: viewContext)
        follower.hexadecimalPublicKey = KeyFixture.bob.publicKey.hex
        
        followOfFollower = Author(context: viewContext)
        followOfFollower.hexadecimalPublicKey = KeyFixture.eve.publicKey.hex
        
        randomPerson = Author(context: viewContext)
        randomPerson.hexadecimalPublicKey = "randomkey123456789"
        
        // Set up social graph
        // Current user follows follower
        let followRelation1 = Follow(context: viewContext)
        followRelation1.source = currentUser
        followRelation1.destination = follower
        currentUser.follows.insert(followRelation1)
        
        // Follower follows followOfFollower
        let followRelation2 = Follow(context: viewContext)
        followRelation2.source = follower
        followRelation2.destination = followOfFollower
        follower.follows.insert(followRelation2)
        
        try viewContext.save()
    }
    
    // Test explicit mention detection
    func testExplicitMentionDetection() {
        // Create notes with different types of mentions
        let noteWithAtMention = Event(context: viewContext)
        noteWithAtMention.author = randomPerson
        noteWithAtMention.content = "Hello @npub\(currentUser.hexadecimalPublicKey!) how are you?"
        noteWithAtMention.kind = EventKind.text.rawValue
        
        let noteWithNostrMention = Event(context: viewContext)
        noteWithNostrMention.author = randomPerson
        noteWithNostrMention.content = "Check this out nostr:npub\(currentUser.hexadecimalPublicKey!)"
        noteWithNostrMention.kind = EventKind.text.rawValue
        
        let noteWithHexMention = Event(context: viewContext)
        noteWithHexMention.author = randomPerson
        noteWithHexMention.content = "Referring to \(currentUser.hexadecimalPublicKey!)"
        noteWithHexMention.kind = EventKind.text.rawValue
        
        let noteWithoutMention = Event(context: viewContext)
        noteWithoutMention.author = randomPerson
        noteWithoutMention.content = "This doesn't mention anyone specifically"
        noteWithoutMention.kind = EventKind.text.rawValue
        
        // Test detection
        XCTAssertTrue(
            pushNotificationService.isUserExplicitlyMentioned(
                event: noteWithAtMention, 
                userPubKey: currentUser.hexadecimalPublicKey!
            )
        )
        
        XCTAssertTrue(
            pushNotificationService.isUserExplicitlyMentioned(
                event: noteWithNostrMention, 
                userPubKey: currentUser.hexadecimalPublicKey!
            )
        )
        
        XCTAssertTrue(
            pushNotificationService.isUserExplicitlyMentioned(
                event: noteWithHexMention, 
                userPubKey: currentUser.hexadecimalPublicKey!
            )
        )
        
        XCTAssertFalse(
            pushNotificationService.isUserExplicitlyMentioned(
                event: noteWithoutMention, 
                userPubKey: currentUser.hexadecimalPublicKey!
            )
        )
    }
    
    // Test following check
    func testFollowingCheck() async {
        let isFollowing = await pushNotificationService.checkIfFollowing(author: follower)
        XCTAssertTrue(isFollowing, "Should recognize follower as followed")
        
        let isFollowingRandom = await pushNotificationService.checkIfFollowing(author: randomPerson)
        XCTAssertFalse(isFollowingRandom, "Should recognize random person as not followed")
        
        // Need to set currentAuthor field for these tests
        pushNotificationService.currentAuthor = currentUser
        
        let isFollowingFollowOfFollower = await pushNotificationService.checkIfFollowing(author: followOfFollower)
        XCTAssertFalse(isFollowingFollowOfFollower, "Should not recognize friend of friend as directly followed")
    }
    
    // Test friend of friend check
    func testFriendOfFriendCheck() async {
        pushNotificationService.currentAuthor = currentUser
        
        let isFriendOfFriend = await pushNotificationService.checkIfFriendOfFriend(author: followOfFollower)
        XCTAssertTrue(isFriendOfFriend, "Should recognize friend of friend relationship")
        
        let isRandomFriendOfFriend = await pushNotificationService.checkIfFriendOfFriend(author: randomPerson)
        XCTAssertFalse(isRandomFriendOfFriend, "Should not recognize random person as friend of friend")
    }
    
    // Test thread replies preference
    func testThreadRepliesPreference() {
        // Create a note by current user
        let originalNote = Event(context: viewContext)
        originalNote.author = currentUser
        originalNote.content = "Original post"
        originalNote.kind = EventKind.text.rawValue
        try? originalNote.sign(withKey: KeyFixture.alice)
        
        // Create a reply to the note without mentioning user
        let replyNote = Event(context: viewContext)
        replyNote.author = randomPerson
        replyNote.content = "This is a reply without explicit mention"
        replyNote.kind = EventKind.text.rawValue
        
        // Link the reply to the original
        let eventRef = EventReference(context: viewContext)
        eventRef.referencedEvent = originalNote
        eventRef.referencingEvent = replyNote
        replyNote.eventReferences = NSMutableOrderedSet(array: [eventRef])
        
        // Verify it's recognized as a reply
        XCTAssertTrue(replyNote.isReply(to: currentUser), "Should recognize note as a reply to current user")
        
        // Test with thread replies enabled
        pushNotificationService.notifyOnThreadReplies = true
        // Would need to test against actual notification creation
        
        // Test with thread replies disabled
        pushNotificationService.notifyOnThreadReplies = false
        // Would need to test against actual notification creation
    }
    
    // Test notification preferences with muted users
    func testNotificationsFromMutedUser() {
        // Create a muted user
        let mutedUser = Author(context: viewContext)
        mutedUser.hexadecimalPublicKey = "mutedkey123456789"
        mutedUser.muted = true
        
        // Create a note from the muted user mentioning current user
        let noteFromMutedUser = Event(context: viewContext)
        noteFromMutedUser.author = mutedUser
        noteFromMutedUser.content = "Hello @npub\(currentUser.hexadecimalPublicKey!)"
        noteFromMutedUser.kind = EventKind.text.rawValue
        
        // We would need to test that notifications from this user are properly filtered
        // This would require integration tests with the actual notification system
    }
}