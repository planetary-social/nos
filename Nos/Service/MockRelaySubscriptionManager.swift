import Foundation
import Starscream

class MockRelaySubscriptionManager: RelaySubscriptionManager {
    var all = [RelaySubscription]()

    var sockets = [WebSocket]()

    var active: [RelaySubscription] {
        all.filter { $0.isActive }
    }

    func active() async -> [RelaySubscription] {
        active
    }

    func all() async -> [RelaySubscription] {
        all
    }

    func sockets() async -> [WebSocket] {
        sockets
    }

    func addSocket(for relayAddress: URL) async -> WebSocket? {
        nil
    }

    func close(socket: WebSocket) async {
    }

    func decrementSubscriptionCount(for subscriptionID: RelaySubscription.ID) async -> Bool {
        false
    }

    func forceCloseSubscriptionCount(for subscriptionID: RelaySubscription.ID) async {
    }

    func markHealthy(socket: WebSocket) async {
    }

    func processSubscriptionQueue() async {
    }

    var queueSubscriptionFilter: Filter?
    func queueSubscription(with filter: Filter, to relayAddress: URL) async -> RelaySubscription.ID {
        queueSubscriptionFilter = filter
        return RelaySubscription.ID()
    }

    func remove(_ socket: any WebSocketClient) async {
    }

    func requestEvents(from socket: any WebSocketClient, subscription: RelaySubscription) async {
    }

    func socket(for address: String) async -> WebSocket? {
        nil
    }

    func socket(for url: URL) async -> WebSocket? {
        nil
    }

    func staleSubscriptions() async -> [RelaySubscription] {
        []
    }

    func subscription(from subscriptionID: RelaySubscription.ID) async -> RelaySubscription? {
        nil
    }

    func trackError(socket: WebSocket) async {
    }

    func updateSubscriptions(with newValue: RelaySubscription) async {
    }
}
