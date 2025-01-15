import CoreData
import XCTest

final class NosNotificationTests: CoreDataTestCase {

    @MainActor func test_outOfNetwork_excludesFollowNotifications() throws {
        // Arrange
        let currentUser = try Author.findOrCreate(by: "current_user", context: testContext)
        let follower = try Author.findOrCreate(by: "follower", context: testContext)
        let unconnectedAuthor = try Author.findOrCreate(by: "unconnected", context: testContext)

        // Create notification with both follower and event from an unconnected author
        let notification = NosNotification(context: testContext)
        notification.follower = follower

        let event = Event(context: testContext)
        event.identifier = "test_event"
        event.author = unconnectedAuthor  // This would normally make it appear in outOfNetwork
        notification.event = event

        try testContext.save()

        // Act
        let fetchRequest = NosNotification.outOfNetworkRequest(for: currentUser)
        let results = try testContext.fetch(fetchRequest)

        // Assert
        XCTAssertEqual(results.count, 0)
    }

    @MainActor func test_outOfNetwork_includesAuthorWithNoFollowers() throws {
        // Arrange
        let currentUser = try Author.findOrCreate(by: "current_user", context: testContext)
        let author = try Author.findOrCreate(by: "author", context: testContext)

        let event = Event(context: testContext)
        event.identifier = "test_event"
        event.author = author

        let notification = NosNotification(context: testContext)
        notification.event = event

        try testContext.save()

        // Act
        let fetchRequest = NosNotification.outOfNetworkRequest(for: currentUser)
        let results = try testContext.fetch(fetchRequest)

        // Assert
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.event?.author?.hexadecimalPublicKey, author.hexadecimalPublicKey)
    }

    @MainActor func test_outOfNetwork_excludesDirectlyFollowedAuthor() throws {
        // Arrange
        let currentUser = try Author.findOrCreate(by: "current_user", context: testContext)
        let bob = try Author.findOrCreate(by: "bob", context: testContext)

        // Current user follows bob
        let follow = Follow(context: testContext)
        follow.source = currentUser
        follow.destination = bob

        let event = Event(context: testContext)
        event.identifier = "test_event"
        event.author = bob

        let notification = NosNotification(context: testContext)
        notification.event = event

        try testContext.save()

        // Act
        let fetchRequest = NosNotification.outOfNetworkRequest(for: currentUser)
        let results = try testContext.fetch(fetchRequest)

        // Assert
        XCTAssertEqual(results.count, 0)
    }

    @MainActor func test_outOfNetwork_excludesIndirectlyConnectedAuthor() throws {
        // Arrange
        let currentUser = try Author.findOrCreate(by: "current_user", context: testContext)
        let alice = try Author.findOrCreate(by: "alice", context: testContext)
        let bob = try Author.findOrCreate(by: "bob", context: testContext)

        // Create follow chain: currentUser -> alice -> bob
        let currentUserFollowsAlice = Follow(context: testContext)
        currentUserFollowsAlice.source = currentUser
        currentUserFollowsAlice.destination = alice

        let aliceFollowsBob = Follow(context: testContext)
        aliceFollowsBob.source = alice
        aliceFollowsBob.destination = bob

        let event = Event(context: testContext)
        event.identifier = "test_event"
        event.author = bob

        let notification = NosNotification(context: testContext)
        notification.event = event

        try testContext.save()

        // Act
        let fetchRequest = NosNotification.outOfNetworkRequest(for: currentUser)
        let results = try testContext.fetch(fetchRequest)

        // Assert
        XCTAssertEqual(results.count, 0)
    }

    // MARK: - In Network Request Tests

    @MainActor func test_inNetwork_includesDirectlyFollowedAuthor() throws {
        // Arrange
        let currentUser = try Author.findOrCreate(by: "current_user", context: testContext)
        let alice = try Author.findOrCreate(by: "alice", context: testContext)

        // Create follow relationship
        let currentUserFollowsAlice = Follow(context: testContext)
        currentUserFollowsAlice.source = currentUser
        currentUserFollowsAlice.destination = alice

        let event = Event(context: testContext)
        event.identifier = "test_event"
        event.author = alice

        let notification = NosNotification(context: testContext)
        notification.event = event

        try testContext.save()

        // Act
        let fetchRequest = NosNotification.inNetworkRequest(for: currentUser)
        let results = try testContext.fetch(fetchRequest)

        // Assert
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.event?.author?.hexadecimalPublicKey, alice.hexadecimalPublicKey)
    }

    @MainActor func test_inNetwork_includesIndirectlyConnectedAuthor() throws {
        // Arrange
        let currentUser = try Author.findOrCreate(by: "current_user", context: testContext)
        let alice = try Author.findOrCreate(by: "alice", context: testContext)
        let bob = try Author.findOrCreate(by: "bob", context: testContext)

        // Create follow chain: currentUser -> alice -> bob
        let currentUserFollowsAlice = Follow(context: testContext)
        currentUserFollowsAlice.source = currentUser
        currentUserFollowsAlice.destination = alice

        let aliceFollowsBob = Follow(context: testContext)
        aliceFollowsBob.source = alice
        aliceFollowsBob.destination = bob

        let event = Event(context: testContext)
        event.identifier = "test_event"
        event.author = bob

        let notification = NosNotification(context: testContext)
        notification.event = event

        try testContext.save()

        // Act
        let fetchRequest = NosNotification.inNetworkRequest(for: currentUser)
        let results = try testContext.fetch(fetchRequest)

        // Assert
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.event?.author?.hexadecimalPublicKey, bob.hexadecimalPublicKey)
    }

    @MainActor func test_inNetwork_excludesAuthorWithNoConnection() throws {
        // Arrange
        let currentUser = try Author.findOrCreate(by: "current_user", context: testContext)
        let unconnectedAuthor = try Author.findOrCreate(by: "unconnected", context: testContext)

        let event = Event(context: testContext)
        event.identifier = "test_event"
        event.author = unconnectedAuthor

        let notification = NosNotification(context: testContext)
        notification.event = event

        try testContext.save()

        // Act
        let fetchRequest = NosNotification.inNetworkRequest(for: currentUser)
        let results = try testContext.fetch(fetchRequest)

        // Assert
        XCTAssertEqual(results.count, 0)
    }

    @MainActor func test_inNetwork_excludesFollowNotifications() throws {
        // Arrange
        let currentUser = try Author.findOrCreate(by: "current_user", context: testContext)
        let follower = try Author.findOrCreate(by: "follower", context: testContext)

        // Create follow relationship to ensure the author would be "in network"
        let follow = Follow(context: testContext)
        follow.source = currentUser
        follow.destination = follower

        // Create notification with both follower and event
        let notification = NosNotification(context: testContext)
        notification.follower = follower

        let event = Event(context: testContext)
        event.identifier = "test_event"
        event.author = follower  // This would normally make it appear in inNetwork
        notification.event = event

        try testContext.save()

        // Act
        let fetchRequest = NosNotification.inNetworkRequest(for: currentUser)
        let results = try testContext.fetch(fetchRequest)

        // Assert
        XCTAssertEqual(results.count, 0, "Should exclude notification even though author is in network")
    }

    // MARK: - Follows Request Tests
    @MainActor func test_followsRequest_includesOnlyFollowNotifications() throws {
        // Arrange
        let user = try Author.findOrCreate(by: "user", context: testContext)
        let follower = try Author.findOrCreate(by: "follower", context: testContext)

        // Create a follow notification
        let followNotification = NosNotification(context: testContext)
        followNotification.follower = follower
        followNotification.user = user
        followNotification.createdAt = Date()

        // Create a regular notification
        let regularNotification = NosNotification(context: testContext)
        regularNotification.event = Event(context: testContext)
        regularNotification.user = user
        regularNotification.createdAt = Date()

        try testContext.save()

        // Act
        let fetchRequest = NosNotification.followsRequest(for: user)
        let results = try testContext.fetch(fetchRequest)

        // Assert
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.follower?.hexadecimalPublicKey, follower.hexadecimalPublicKey)
    }

    // MARK: - All Notifications Tests
    @MainActor func test_allRequest_includesAllNotificationsForUser() throws {
        // Arrange
        let user = try Author.findOrCreate(by: "user", context: testContext)
        let follower = try Author.findOrCreate(by: "follower", context: testContext)
        let eventAuthor = try Author.findOrCreate(by: "author", context: testContext)

        // Create a follow notification
        let followNotification = NosNotification(context: testContext)
        followNotification.follower = follower
        followNotification.user = user
        followNotification.createdAt = Date()

        // Create an event notification
        let event = Event(context: testContext)
        event.author = eventAuthor
        event.identifier = "test_event"

        let eventNotification = NosNotification(context: testContext)
        eventNotification.event = event
        eventNotification.user = user
        eventNotification.createdAt = Date()

        try testContext.save()

        // Act
        let fetchRequest = NosNotification.allRequest(for: user)
        let results = try testContext.fetch(fetchRequest)

        // Assert
        XCTAssertEqual(results.count, 2)
    }

    @MainActor func test_allRequest_sortsNotificationsByCreatedAtDescending() throws {
        // Arrange
        let user = try Author.findOrCreate(by: "user", context: testContext)

        let laterDate = Calendar.current.date(byAdding: .hour, value: -2, to: .now)!
        let recentDate = Calendar.current.date(byAdding: .hour, value: -1, to: .now)!

        let laterNotification = NosNotification(context: testContext)
        laterNotification.user = user
        laterNotification.createdAt = laterDate

        let recentNotification = NosNotification(context: testContext)
        recentNotification.user = user
        recentNotification.createdAt = recentDate

        try testContext.save()

        // Act
        let fetchRequest = NosNotification.allRequest(for: user)
        let results = try testContext.fetch(fetchRequest)

        // Assert
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0].createdAt, recentDate)
        XCTAssertEqual(results[1].createdAt, laterDate)
    }
}
