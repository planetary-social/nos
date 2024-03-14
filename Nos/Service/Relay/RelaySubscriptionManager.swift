import Starscream
import Foundation
import Logger

/// An actor that manages state for a `RelayService` including lists of open sockets and subscriptions.
actor RelaySubscriptionManager {
    
    // MARK: - Public Properties
    
    var all = [RelaySubscription]()
    
    var sockets = [WebSocket]()
    
    var active: [RelaySubscription] {
        all.filter { $0.isActive }
    }
    
    // MARK: - Mutating the list of subscriptions
    
    func subscription(from filter: Filter) -> RelaySubscription? {
        subscription(from: filter.id)
    }
    
    func subscription(from subscriptionID: RelaySubscription.ID) -> RelaySubscription? {
        if let subscriptionIndex = self.all.firstIndex(where: { $0.id == subscriptionID }) {
            return all[subscriptionIndex]
        } else {
            return nil
        }
    }
    
    func updateSubscriptions(with newValue: RelaySubscription) {
        if let subscriptionIndex = self.all.firstIndex(where: { $0.id == newValue.id }) {
            all[subscriptionIndex] = newValue
        } else {
            all.append(newValue)
        }
    }
    
    private func removeSubscription(with subscriptionID: RelaySubscription.ID) {
        if let subscriptionIndex = self.all.firstIndex(
            where: { $0.id == subscriptionID }
        ) {
            all.remove(at: subscriptionIndex)
        }
    }
    
    func forceCloseSubscriptionCount(for subscriptionID: RelaySubscription.ID) {
        removeSubscription(with: subscriptionID)
    }
    
    @discardableResult
    func decrementSubscriptionCount(for subscriptionID: RelaySubscription.ID) async -> Bool {
        if var subscription = subscription(from: subscriptionID) {
            if subscription.referenceCount == 1 {
                removeSubscription(with: subscriptionID)
                return false
            } else {
                subscription.referenceCount -= 1
                updateSubscriptions(with: subscription)
                return true
            }
        }
        return false
    }
    
    /// Finds stale subscriptions, removes them from the subscription list, and returns them.
    func staleSubscriptions() async -> [RelaySubscription] {
        var staleSubscriptions = [RelaySubscription]()
        for subscription in active {
            if subscription.isOneTime, 
                let filterStartedAt = subscription.subscriptionStartDate,
                filterStartedAt.distance(to: .now) > 10 {
                staleSubscriptions.append(subscription)
            }
        }
        for subscription in staleSubscriptions {
            forceCloseSubscriptionCount(for: subscription.id)
        }
        return staleSubscriptions
    }

    func addSocket(for relayAddress: URL) -> WebSocket? {
        guard !sockets.contains(where: { $0.request.url == relayAddress }) else {
            return nil
        }
        
        var request = URLRequest(url: relayAddress)
        request.timeoutInterval = 10
        let socket = WebSocket(request: request)
        sockets.append(socket)
        return socket
    }
    
    func close(socket: WebSocket) {
        socket.disconnect()
        if let index = sockets.firstIndex(where: { $0 === socket }) {
            sockets.remove(at: index)
        }
    }
    
    func remove(_ socket: WebSocketClient) {
        if let index = sockets.firstIndex(where: { $0 === socket }) {
            sockets.remove(at: index)
        }
    }
    
    func socket(for address: String) -> WebSocket? {
        if let index = sockets.firstIndex(where: { $0.request.url!.absoluteString == address }) {
            return sockets[index]
        }
        return nil
    }
    
    func socket(for url: URL) -> WebSocket? {
        if let index = sockets.firstIndex(where: { $0.request.url == url }) {
            return sockets[index]
        }
        return nil
    }
    
    // MARK: - Talking to Relays
    
    private let subscriptionLimit = 10
    private let minimimumOneTimeSubscriptions = 1
    
    func processSubscriptionQueue() async {
        
        let waitingLongSubscriptions = all.filter { !$0.isOneTime && !$0.isActive }
        let waitingOneTimeSubscriptions = all.filter { $0.isOneTime && !$0.isActive }
        
        waitingOneTimeSubscriptions.forEach { start(subscription: $0) }
        waitingLongSubscriptions.forEach { start(subscription: $0) }
        
        Log.debug("\(active.count) active subscriptions. \(all.count - active.count) subscriptions waiting in queue.")
    }
    
    func queueSubscription(with filter: Filter, to relayAddress: URL) async -> RelaySubscription.ID {
        var subscription = RelaySubscription(filter: filter, relayAddress: relayAddress)
        
        if let existingSubscription = self.subscription(from: subscription.id) {
            // dedup
            subscription = existingSubscription
        }
        
        subscription.referenceCount += 1
        updateSubscriptions(with: subscription)
        
        return subscription.id
    }
    
    private func start(subscription: RelaySubscription) {
        var subscription = subscription
        subscription.subscriptionStartDate = .now
        updateSubscriptions(with: subscription)
        Log.debug("starting subscription: \(subscription.id), filter: \(subscription.filter)")
        if let socket = socket(for: subscription.relayAddress) {
            requestEvents(from: socket, subscription: subscription)
        }
    }
    
    /// Takes a RelaySubscription model and makes a websockets request to the given socket
    func requestEvents(from socket: WebSocketClient, subscription: RelaySubscription) {
        do {
            // Track this so we can close requests if needed
            let request: [Any] = ["REQ", subscription.id, subscription.filter.dictionary]
            let requestData = try JSONSerialization.data(withJSONObject: request)
            let requestString = String(data: requestData, encoding: .utf8)!
            Log.debug("REQ for \(subscription.id) sent to \(socket.host)")
            socket.write(string: requestString)
        } catch {
            Log.error("Error: Could not send request \(error.localizedDescription)")
        }
    }
}
