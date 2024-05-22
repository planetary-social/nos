import XCTest

class RelayServiceTests: XCTestCase {
    func test_requestContactList_uses_correct_filter() async throws {
        let since = Date()
        let expectedFilter = Filter(
            authorKeys: ["test"],
            kinds: [.contactList],
            since: since
        )
        let mockSubscriptionManager = MockRelaySubscriptionManager()
        let subject = RelayService(subscriptionManager: mockSubscriptionManager)
        _ = await subject.requestContactList(for: "test", since: since)

        let resultFilter = try XCTUnwrap(mockSubscriptionManager.queueSubscriptionFilter)
        XCTAssertEqual(resultFilter, expectedFilter)
    }
}
