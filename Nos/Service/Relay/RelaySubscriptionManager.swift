import Starscream
import Foundation
import Logger

protocol RelaySubscriptionManager {
    func active() async -> [RelaySubscription]
    func all() async -> [RelaySubscription]
    func sockets() async -> [WebSocket]

    func addSocket(for relayAddress: URL) async -> WebSocket?
    func close(socket: WebSocket) async
    @discardableResult
    func decrementSubscriptionCount(for subscriptionID: RelaySubscription.ID) async -> Bool
    func forceCloseSubscriptionCount(for subscriptionID: RelaySubscription.ID) async
    func markHealthy(socket: WebSocket) async
    func processSubscriptionQueue() async
    func queueSubscription(with filter: Filter, to relayAddress: URL) async -> RelaySubscription.ID
    func remove(_ socket: WebSocketClient) async
    func requestEvents(from socket: WebSocketClient, subscription: RelaySubscription) async
    func socket(for address: String) async -> WebSocket?
    func socket(for url: URL) async -> WebSocket?
    func staleSubscriptions() async -> [RelaySubscription]
    func subscription(from subscriptionID: RelaySubscription.ID) async -> RelaySubscription?
    func trackError(socket: WebSocket) async
    func updateSubscriptions(with newValue: RelaySubscription) async
}

/// An actor that manages state for a `RelayService` including lists of open sockets and subscriptions.
actor RelaySubscriptionManagerActor: RelaySubscriptionManager {
    // MARK: - Public Properties
    
    var all = [RelaySubscription]()
    
    var sockets = [WebSocket]()
    
    var active: [RelaySubscription] {
        all.filter { $0.isActive }
    }

    /// Limit of the number of active subscriptions in a single relay
    private let queueLimit = 25

    // MARK: - Protocol conformance
    
    func active() async -> [RelaySubscription] {
        active
    }

    func all() async -> [RelaySubscription] {
        all
    }

    func sockets() async -> [WebSocket] {
        sockets
    }

    // MARK: - Mutating the list of subscriptions
    
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
    
    /// Lets the manager know that there is one less subscriber for the given subscription. If there are no 
    /// more subscribers this function returns `true`. 
    /// 
    /// Note that this does not send a close message on the websocket or close the socket. Right now those actions
    /// are performed by the RelayService. It's yucky though. Maybe we should make the RelaySubscriptionManager
    /// do that in the future.
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
            if subscription.closesAfterResponse, 
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
        
        if let priorError = errored[relayAddress],
            priorError.nextRetry > Date.now {
            // This socket has errored recently and it isn't yet time to retry again.
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
        all.removeAll { subscription in
            subscription.relayAddress == socket.url
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
    
    func processSubscriptionQueue() async {
        var waitingSubscriptions = [RelaySubscription]()

        // Counter to track the number of active subscriptions per relay
        var activeSubscriptionsCount = [URL: Int]()

        all.forEach { relaySubscription in
            if relaySubscription.isActive {
                // Update active subscriptions counter
                let relayAddress = relaySubscription.relayAddress
                if let currentCount = activeSubscriptionsCount[relayAddress] {
                    activeSubscriptionsCount[relayAddress] = currentCount + 1
                } else {
                    activeSubscriptionsCount[relayAddress] = 1
                }
            } else {
                waitingSubscriptions.append(relaySubscription)
            }
        }

        // Start waiting relay subscriptions if they don't exceed the queue
        // limit
        waitingSubscriptions.forEach { relaySubscription in
            let relayAddress = relaySubscription.relayAddress
            if let subscriptionsCount = activeSubscriptionsCount[relayAddress] {
                if subscriptionsCount < queueLimit {
                    start(subscription: relaySubscription)
                    activeSubscriptionsCount[relayAddress] = subscriptionsCount + 1
                }
            } else {
                start(subscription: relaySubscription)
                activeSubscriptionsCount[relayAddress] = 1
            }
        }
        
        #if DEBUG
        let allCount = all.count
        let activeCount = active.count
        if allCount > activeCount {
            Log.debug("\(allCount - activeCount) subscriptions waiting in queue.")
        }
        #endif
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
            socket.write(string: requestString)
        } catch {
            Log.error("Error: Could not send request \(error.localizedDescription)")
        }
    }
    
    // MARK: - Error Tracking 
    
    /// A map that keeps track of errors we have received from websockets. 
    private var errored: [URL: WebsocketErrorEvent] = [:]
    
    /// This constant is used to calculate the maximum amount of time we will wait before retrying an errored socket.
    /// We backoff exponentially for 2^x seconds, increasing x by 1 on each consecutive error 
    /// until x == `maxBackoffPower`.
    static let maxBackoffPower = 9
    
    /// A function that should be called when a websocket cannot be opened or is closed due to an error.
    /// The `RelaySubscriptionManager` will use this data to prevent subsequent calls to reopen the socket using an 
    /// exponential backoff strategy. So instead of retrying to open the socket every second we will wait 1 second, 
    /// then 2, then 4, then 8, up to 2^`maxBackoffPower`.
    func trackError(socket: WebSocket) {
        guard let relayAddress = socket.request.url else {
            return 
        }
        
        if var priorError = errored[relayAddress] {
            priorError.trackRetry()
            errored[relayAddress] = priorError
        } else {
            errored[relayAddress] = WebsocketErrorEvent()
        }
    }
    
    /// This should be called when a socket is successfully opened. It will reset the error count for the socket
    /// if it was above zero.
    func markHealthy(socket: WebSocket) {
        guard let url = socket.request.url else { 
            return 
        }
        
        errored.removeValue(forKey: url)
    }
}

/// A container that tracks how many times we have tried unsuccessfully to open a websocket and the next time we should
/// try again.
fileprivate struct WebsocketErrorEvent {
    var retryCounter: Int = 1
    var nextRetry: Date = .now
    
    mutating func trackRetry() {
        self.retryCounter += 1
        let delaySeconds = NSDecimalNumber(
            decimal: pow(2, min(retryCounter, RelaySubscriptionManagerActor.maxBackoffPower))
        )
        self.nextRetry = Date(timeIntervalSince1970: Date.now.timeIntervalSince1970 + delaySeconds.doubleValue)
    }
}
