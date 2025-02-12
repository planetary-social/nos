import Foundation
import Starscream

final class MockRelaySubscriptionManager: RelaySubscriptionManager {
    
    var all = [RelaySubscription]()

    var sockets = [WebSocket]()

    var active: [RelaySubscription] {
        all.filter { $0.isActive }
    }

    func active() async -> [RelaySubscription] {
        active
    }

    func set(socketQueue: DispatchQueue?, delegate: Starscream.WebSocketDelegate?) async {
    }

    func sockets() async -> [WebSocket] {
        sockets
    }

    func close(socket: WebSocket) async {
    }
    
    func trackAuthenticationRequest(from socket: WebSocket, responseID: RawNostrID) async {
    }
    
    func checkAuthentication(
        success: Bool, 
        from socket: WebSocket, 
        eventID: RawNostrID, 
        message: String?
    ) async -> Bool {
        false
    }

    func decrementSubscriptionCount(for subscriptionID: RelaySubscription.ID) async {
    }

    func closeSubscription(with subscriptionID: RelaySubscription.ID) async {
    }

    func trackConnected(socket: WebSocket) async {
    }

    func processSubscriptionQueue() async {
    }

    var queueSubscriptionFilter: Filter?
    func queueSubscription(with filter: Filter, to relayAddress: URL) async -> RelaySubscription {
        queueSubscriptionFilter = filter
        return RelaySubscription(filter: filter, relayAddress: relayAddress)
    }
    
    func receivedClose(for subscriptionID: RelaySubscription.ID, from socket: WebSocket) async {
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
}
