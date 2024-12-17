import XCTest

class RelayServiceTests: XCTestCase {
    func test_requestContactList_uses_correct_filter() async throws {
        let since = Date()
        let expectedFilter = Filter(
            authorKeys: ["test"],
            kinds: [.contactList],
            limit: 1,
            since: since
        )
        let mockSubscriptionManager = MockRelaySubscriptionManager()
        let subject = RelayService(subscriptionManager: mockSubscriptionManager)
        _ = await subject.requestContactList(for: "test", since: since)

        let resultFilter = try XCTUnwrap(mockSubscriptionManager.queueSubscriptionFilter)
        XCTAssertEqual(resultFilter, expectedFilter)
    }

    func test_requestFollowSets_uses_correct_filter() async throws {
        let since = Date()
        let expectedFilter = Filter(
            authorKeys: ["test"],
            kinds: [.followSet],
            since: since
        )
        let mockSubscriptionManager = MockRelaySubscriptionManager()
        let subject = RelayService(subscriptionManager: mockSubscriptionManager)
        _ = await subject.requestAuthorLists(for: "test", since: since)

        let resultFilter = try XCTUnwrap(mockSubscriptionManager.queueSubscriptionFilter)
        XCTAssertEqual(resultFilter, expectedFilter)
    }
}
