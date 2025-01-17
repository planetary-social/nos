import CoreData
import XCTest

final class NosNotificationTests: CoreDataTestCase {

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
