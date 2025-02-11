import Foundation 

/// A version of the relay service that won't talk to real relays.
final class MockRelayService: RelayService {
    init() {
        let mockSubscriptionManager = MockRelaySubscriptionManager()
        super.init(subscriptionManager: mockSubscriptionManager)
    }
}
