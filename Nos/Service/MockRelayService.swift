/// A version of the relay service that won't talk to real relays.
class MockRelayService: RelayService {
    init() {
        super.init(subscriptionManager: MockRelaySubscriptionManager())
    }
}
