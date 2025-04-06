import XCTest
import Combine
@testable import Nos

final class NotificationPreferenceTests: CoreDataTestCase {
    var pushNotificationService: PushNotificationService!
    var currentUser: Author!
    var otherUser: Author!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        pushNotificationService = PushNotificationService()
        
        // Create test users
        currentUser = Author(context: viewContext)
        currentUser.publicKey = KeyFixture.alice.publicKey
        
        otherUser = Author(context: viewContext)
        otherUser.publicKey = KeyFixture.bob.publicKey
        
        try viewContext.save()
    }
    
    func testExplicitMentionDetection() {
        // Create a note with an explicit @npub mention
        let noteWithExplicitMention = Event(context: viewContext)
        noteWithExplicitMention.author = otherUser
        noteWithExplicitMention.content = "Hello @npub\(currentUser.hexadecimalPublicKey) how are you?"
        noteWithExplicitMention.kind = 1
        
        // Create a note with only a p-tag reference but no explicit mention
        let noteWithPTagOnly = Event(context: viewContext)
        noteWithPTagOnly.author = otherUser
        noteWithPTagOnly.content = "This is a reply without explicitly mentioning anyone."
        noteWithPTagOnly.kind = 1
        let authorRef = AuthorReference(context: viewContext)
        authorRef.pubkey = currentUser.hexadecimalPublicKey
        noteWithPTagOnly.authorReferences = NSMutableOrderedSet(array: [authorRef])
        
        // Test detection
        XCTAssertTrue(
            pushNotificationService.isUserExplicitlyMentioned(
                event: noteWithExplicitMention, 
                userPubKey: currentUser.hexadecimalPublicKey
            )
        )
        
        XCTAssertFalse(
            pushNotificationService.isUserExplicitlyMentioned(
                event: noteWithPTagOnly, 
                userPubKey: currentUser.hexadecimalPublicKey
            )
        )
    }
    
    func testNotificationFilteringPreference() {
        // Test preference storage and retrieval
        
        // Default should be allMentions
        XCTAssertEqual(pushNotificationService.notificationPreference, .allMentions)
        
        // Set to explicitMentionsOnly
        pushNotificationService.notificationPreference = .explicitMentionsOnly
        XCTAssertEqual(pushNotificationService.notificationPreference, .explicitMentionsOnly)
        
        // Set back to allMentions
        pushNotificationService.notificationPreference = .allMentions
        XCTAssertEqual(pushNotificationService.notificationPreference, .allMentions)
    }
}
