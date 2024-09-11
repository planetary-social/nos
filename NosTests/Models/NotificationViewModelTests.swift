import CoreData
import Foundation
import XCTest

final class NotificationViewModelTests: CoreDataTestCase {
    
    @MainActor
    func testZapProfileNotification() throws {
        let zapRequest = try zapRequestEvent(filename: "zap_request")
        let recipient = try XCTUnwrap(Author.findOrCreate(by: "alice", context: testContext))
        let viewModel = NotificationViewModel(note: zapRequest, user: recipient)
        
        let notification = viewModel.notificationCenterRequest
        XCTAssertEqual(notification.content.title, "npub1vnz0m... ⚡️ zapped you 3,500 sats!")
        XCTAssertEqual(notification.content.body, "Zapped you!")
    }
    
    @MainActor
    func testZapProfileNotification_noAmount() throws {
        let zapRequest = try zapRequestEvent(filename: "zap_request_no_amount")
        let recipient = try XCTUnwrap(Author.findOrCreate(by: "alice", context: testContext))
        let viewModel = NotificationViewModel(note: zapRequest, user: recipient)
        
        let notification = viewModel.notificationCenterRequest
        XCTAssertEqual(notification.content.title, "npub1vnz0m... ⚡️ zapped you!")
        XCTAssertEqual(notification.content.body, "Zap!")
    }
    
    @MainActor
    func testZapProfileNotification_oneSat() throws {
        let zapRequest = try zapRequestEvent(filename: "zap_request_one_sat")
        let recipient = try XCTUnwrap(Author.findOrCreate(by: "alice", context: testContext))
        let viewModel = NotificationViewModel(note: zapRequest, user: recipient)
        
        let notification = viewModel.notificationCenterRequest
        XCTAssertEqual(notification.content.title, "npub1vnz0m... ⚡️ zapped you 1 sat!")
        XCTAssertEqual(notification.content.body, "Only one sat")
    }
    
    // MARK: Helpers
    
    @MainActor
    private func zapRequestEvent(filename: String) throws -> Event {
        let jsonData = try jsonData(filename: filename)
        let jsonEvent = try JSONDecoder().decode(JSONEvent.self, from: jsonData)
        let zapRequestEvent = try XCTUnwrap(
            try EventProcessor.parse(
                jsonEvent: jsonEvent,
                from: nil,
                in: testContext,
                skipVerification: true
            )
        )
        return zapRequestEvent
    }
}
