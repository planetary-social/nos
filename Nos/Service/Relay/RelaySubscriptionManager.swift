import Starscream
import Foundation
import Logger

protocol RelaySubscriptionManager {
    func active() async -> [RelaySubscription]

    func set(socketQueue: DispatchQueue?, delegate: WebSocketDelegate?) async

    func decrementSubscriptionCount(for subscriptionID: RelaySubscription.ID) async 
    func closeSubscription(with subscriptionID: RelaySubscription.ID) async
    func trackConnected(socket: WebSocket) async
    func processSubscriptionQueue() async
    func queueSubscription(with filter: Filter, to relayAddress: URL) async -> RelaySubscription
    func receivedClose(for subscriptionID: RelaySubscription.ID, from socket: WebSocket) async
    
    func close(socket: WebSocket) async
    func trackAuthenticationRequest(from socket: WebSocket, responseID: RawNostrID) async
    func checkAuthentication(success: Bool, from socket: WebSocket, eventID: RawNostrID, message: String?) async -> Bool
    func sockets() async -> [WebSocket] 
    func socket(for address: String) async -> WebSocket?
    func socket(for url: URL) async -> WebSocket?
    func subscription(from subscriptionID: RelaySubscription.ID) async -> RelaySubscription?
    func trackError(socket: WebSocket) async
}

/// An actor that manages state for a `RelayService` including lists of open sockets and subscriptions.
@globalActor
actor RelaySubscriptionManagerActor: RelaySubscriptionManager {
    
    static let shared = RelaySubscriptionManagerActor()
    
    // MARK: - Public Properties
    
    var all = [RelaySubscription]()
    
    /// All websocket connections under management, mapped by their relay URL.
    var socketConnections = [URL: WebSocketConnection]()
    
    var active: [RelaySubscription] {
        all.filter { $0.isActive }
    }
    
    /// Limit of the number of active subscriptions in a single relay
    private let queueLimit = 10

    // MARK: - Protocol conformance
    
    func active() async -> [RelaySubscription] {
        active
    }

    private var socketQueue: DispatchQueue?
    private var delegate: WebSocketDelegate?
    
    func set(socketQueue: DispatchQueue?, delegate: WebSocketDelegate?) {
        self.socketQueue = socketQueue
        self.delegate = delegate
    }

    // MARK: - Mutating the list of subscriptions
    
    func subscription(from subscriptionID: RelaySubscription.ID) -> RelaySubscription? {
        if let subscriptionIndex = self.all.firstIndex(where: { $0.id == subscriptionID }) {
            return all[subscriptionIndex]
        } else {
            return nil
        }
    }
    
    /// Lets the manager know that there is one less subscriber for the given subscription. If there are no 
    /// more subscribers this function closes the subscription. 
    /// 
    /// Incrementing the subscription count is done by `queueSubscription(with:to:)`.
    func decrementSubscriptionCount(for subscriptionID: RelaySubscription.ID) {
        if let subscription = subscription(from: subscriptionID) {
            if subscription.referenceCount == 1 {
                closeSubscription(subscription)
            } else {
                subscription.referenceCount -= 1
            }
        }
    }
            
    /// Closes the subscription with the given ID. Sends a "CLOSE" message to the relay and removes the subscription
    /// object from management.
    func closeSubscription(with subscriptionID: RelaySubscription.ID) {
        guard let subscription = subscription(from: subscriptionID) else {
            Log.error("Tried to force close non-existent subscription \(subscriptionID)")
            return
        }
        closeSubscription(subscription)
    }
    
    /// Closes the given subscription. Sends a "CLOSE" message to the relay and removes the subscription
    /// object from management.
    private func closeSubscription(_ subscription: RelaySubscription) {
        sendClose(for: subscription)
        removeSubscription(with: subscription.id)
    }
    
    /// Remove just removes a subscription from our internal tracking. It doesn't send the relay any notification
    /// that we are closing the subscription.
    private func removeSubscription(with subscriptionID: RelaySubscription.ID) {
        if let subscriptionIndex = self.all.firstIndex(
            where: { $0.id == subscriptionID }
        ) {
            all.remove(at: subscriptionIndex)
        }
    }

    
    /// Closes subscriptions that are supposed to close after a response but haven't returned any response for a while.
    private func closeStaleSubscriptions() {
        for subscription in active {
            if subscription.closesAfterResponse, 
                let filterStartedAt = subscription.subscriptionStartDate,
                filterStartedAt.distance(to: .now) > 10 {
                closeSubscription(subscription)
            }
        }
    }
    
    // MARK: - Socket Management
    
    /// Opens sockets to any relays that we have an open subscription for that don't already have a socket.
    func openSockets() {
        var relayAddresses = Set<URL>()
        all.forEach { relayAddresses.insert($0.relayAddress) }

        for relayAddress in relayAddresses {
            let connection = findOrCreateSocket(for: relayAddress)
            
            switch connection.state {
            case .errored(let error):
                if error.nextRetry > Date.now {
                    continue
                } else {
                    fallthrough
                }
            case .disconnected:
                connection.socket.connect()
                connection.state = .connecting
            case .connected, .connecting, .authenticating:
                continue
            }
        }
    }
    
    /// Creates a WebSocketConnection for a relay. This is not idempotent - make sure it's called only once for 
    /// each relay.
    private func findOrCreateSocket(for relayAddress: URL) -> WebSocketConnection {
        if let existingConnection = socketConnections[relayAddress] {
            return existingConnection
        } 
        
        var request = URLRequest(url: relayAddress)
        request.timeoutInterval = 10
        let socket = WebSocket(request: request, useCustomEngine: false)
        if let socketQueue {
            socket.callbackQueue = socketQueue
        } else {
            Log.error("Created socket with no callbackQueue.")
        }
        socket.delegate = delegate
        let connection = WebSocketConnection(socket: socket)
        socketConnections[relayAddress] = connection
        return connection
    }
    
    /// Closes a socket, closes & removes all subscriptions from that socket and stops tracking it. 
    func close(socket: WebSocket) {
        socket.disconnect()
        if let relayAddress = socket.url {
            for subscription in all where subscription.relayAddress == relayAddress {
                closeSubscription(with: subscription.id)
            }
            socketConnections.removeValue(forKey: relayAddress)
        }
    }
    
    /// Tracks that a relay sent us an AUTH message, so we can change the socket state to .authenticating
    func trackAuthenticationRequest(from socket: WebSocket, responseID: RawNostrID) {
        if let relayAddress = socket.url, let connection = socketConnections[relayAddress] {
            // Close open subscriptions if any.
            active.forEach { subscription in
                if subscription.relayAddress == relayAddress {
                    subscription.subscriptionStartDate = nil
                    socket.write(string: "[\"CLOSE\", \"\(subscription.id)\"]")
                }
            }
            connection.state = .authenticating(responseID)
        }
    }
    
    /// Checks the ID of an "OK" message from a relay to see if it matches any authentication events we have sent.
    /// If it does we mark the relay as .connected. If it doesn't then we do nothing, so this function is safe to be 
    /// called on every "OK" message. 
    func checkAuthentication(success: Bool, from socket: WebSocket, eventID: RawNostrID, message: String?) -> Bool {
        guard let relayAddress = socket.url, let connection = socketConnections[relayAddress] else {
            return false
        }
        
        if case .authenticating(let responseID) = connection.state, responseID == eventID {
            if success {
                Log.info("Successfully authenticated with \(relayAddress)")
                connection.state = .connected
                processSubscriptionQueue()
            } else {
                Log.error("Failed to authenticate with \(relayAddress). Message: \(String(describing: message))")
                trackError(socket: socket)
            }
            return true
        } 
        return false
    }
    
    func sockets() -> [WebSocket] {
        socketConnections.values.map { $0.socket }
    }
    
    func socket(for address: String) -> WebSocket? {
        if let url = URL(string: address) {
            return socket(for: url)
        }
        return nil
    }
    
    func socket(for url: URL) -> WebSocket? {
        socketConnections[url]?.socket
    }
    
    // MARK: - Talking to Relays
    
    /// Looks at the current state of sockets and subscriptions and opens new ones. It includes logic to 
    /// open websockets to service queued subscriptions and to limit the number of concurrent subscriptions for a given
    /// relay.
    ///
    /// It's called at appropriate times internally but can also be called externally in a loop. Idempotent.
    func processSubscriptionQueue() {
        closeStaleSubscriptions()
        
        openSockets()
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
            guard let socket = socketConnections[relayAddress], case .connected = socket.state else {
                return
            }
            
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
    }
    
    func queueSubscription(with filter: Filter, to relayAddress: URL) async -> RelaySubscription {
        var subscription = RelaySubscription(filter: filter, relayAddress: relayAddress)
        
        if let existingSubscription = self.subscription(from: subscription.id) {
            // dedup
            subscription = existingSubscription
        } else {
            all.append(subscription)
        }
        
        subscription.referenceCount += 1
        
        if socketConnections[relayAddress] == nil {
            socketConnections[relayAddress] = findOrCreateSocket(for: relayAddress)
        }
        
        return subscription
    }
    
    private func start(subscription: RelaySubscription) {
        let subscription = subscription
        subscription.subscriptionStartDate = .now
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
            let requestString = String(decoding: requestData, as: UTF8.self)
            socket.write(string: requestString)
        } catch {
            Log.error("Error: Could not send request \(error.localizedDescription)")
        }
    }
    
    /// Notifies the relay that we are closing the subscription with the given ID.
    private func sendClose(for subscriptionID: RelaySubscription.ID) {
        guard let subscription = subscription(from: subscriptionID) else {
            Log.error("Tried to close a non-existing subscription \(subscriptionID)")
            return
        } 
        sendClose(for: subscription)
    }
    
    /// Notifies the associated relay that we are closing the given subscription.
    func sendClose(for subscription: RelaySubscription) {
        guard let socket = socket(for: subscription.relayAddress) else {
            Log.error("Tried to close a non-existing subscription \(subscription.id)")
            return
        } 
        sendClose(from: socket, subscriptionID: subscription.id)
    }
    
    /// Writes a CLOSE message to the given socket, letting the relay know we are done with given subscription ID.
    private func sendClose(from socket: WebSocketClient, subscriptionID: RelaySubscription.ID) {
        do {
            let request: [Any] = ["CLOSE", subscriptionID]
            let requestData = try JSONSerialization.data(withJSONObject: request)
            let requestString = String(decoding: requestData, as: UTF8.self)
            socket.write(string: requestString)
        } catch {
            Log.error("Error: Could not send close \(error.localizedDescription)")
        }
    }
    
    func receivedClose(for subscriptionID: RelaySubscription.ID, from socket: WebSocket) {
        if let subscription = subscription(from: subscriptionID) {
            // Move this subscription to the end of the queue where it will be retried
            removeSubscription(with: subscriptionID)
            subscription.subscriptionStartDate = nil
            all.append(subscription)
        }
    }
    
    // MARK: - Error Tracking 

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
        
        guard let connection = socketConnections[relayAddress] else {
            return
        }
        
        if case WebSocketState.errored(var priorError) = connection.state {
            priorError.trackRetry()
            connection.state = .errored(priorError)
            Log.info("Tracking error on websocket connection to \(relayAddress)")
        } else {
            connection.state = .errored(WebSocketErrorEvent())
        }
    }
    
    /// This should be called when a socket is successfully opened. It will reset the error count for the socket
    /// if it was above zero.
    func trackConnected(socket: WebSocket) {
        guard let url = socket.request.url else { 
            return 
        }
        
        guard let connection = socketConnections[url] else {
            return
        }
       
        let oldState = connection.state
        guard oldState != .connected else {
            return
        }
        
        connection.state = .connected
        Log.info("\(url) has connected")
        
        for subscription in active where subscription.relayAddress == url {
            requestEvents(from: connection.socket, subscription: subscription)
        }
        processSubscriptionQueue()
    }
}
