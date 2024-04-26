import Foundation
import Starscream
import CoreData
import Logger
import Dependencies
import UIKit

// swiftlint:disable file_length

/// A service that maintains connections to Nostr Relay servers and executes requests for data from those relays
/// in the form of `Filters` and `RelaySubscription`s.
final class RelayService: ObservableObject {
    
    private var subscriptions: RelaySubscriptionManager
    private var processSubscriptionQueueTimer: AsyncTimer?
    private var backgroundProcessTimer: AsyncTimer?
    private var eventProcessingLoop: Task<Void, Error>?
    private var backgroundContext: NSManagedObjectContext 
    private var parseContext: NSManagedObjectContext 
    private var processingQueue = DispatchQueue(label: "RelayService-processing", qos: .userInitiated)
    private var parseQueue = ParseQueue()

    @Dependency(\.analytics) private var analytics
    @MainActor @Dependency(\.currentUser) private var currentUser
    @Published var numberOfConnectedRelays: Int = 0
    
    init() {
        self.subscriptions = RelaySubscriptionManager()
        @Dependency(\.persistenceController) var persistenceController
        self.backgroundContext = persistenceController.newBackgroundContext()
        self.parseContext = persistenceController.parseContext
        
        self.eventProcessingLoop = Task(priority: .userInitiated) { [weak self] in
            try Task.checkCancellation()
            while true {
                do { 
                    let foundEvents = try await self?.batchParseEvents()
                    if foundEvents == false {
                        try await Task.sleep(for: .milliseconds(50))
                    }
                } catch {
                    Log.error("RelayService: Error parsing events: \(error.localizedDescription)")
                }
            }
        }

        self.processSubscriptionQueueTimer = AsyncTimer(
            timeInterval: 1, 
            priority: .high, 
            firesImmediately: false
        ) { [weak self] in
            await self?.processSubscriptionQueue()
        }
        
        // TODO: fire this after all relays have connected, not right on init
        self.backgroundProcessTimer = AsyncTimer(timeInterval: 60, firesImmediately: true, onFire: { [weak self] in
            await self?.publishFailedEvents()
            await self?.deleteExpiredEvents()
        })
        
        Task { @MainActor in
            currentUser.viewContext = persistenceController.container.viewContext
            await openSockets()
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    deinit {
        processSubscriptionQueueTimer?.cancel()
        backgroundProcessTimer?.cancel()
        eventProcessingLoop?.cancel()
    }
    
    @objc func appWillEnterForeground() {
        Task { await openSockets() }
    }
    
    private func handleError(_ error: Error?, from socket: WebSocketClient) {
        if let error {
            Log.debug("websocket error: \(error) from: \(socket.host)")
        } else {
            Log.debug("unknown websocket error from: \(socket.host)")
        }
    }
}

// MARK: Close subscriptions
extension RelayService {
    
    func decrementSubscriptionCount(for subscriptionIDs: [String]) {
        for subscriptionID in subscriptionIDs {
            self.decrementSubscriptionCount(for: subscriptionID)
        }
    }
    
    func decrementSubscriptionCount(for subscriptionID: String) {
        Task {
            let subscriptionStillActive = await subscriptions.decrementSubscriptionCount(for: subscriptionID)
            if !subscriptionStillActive {
                await self.sendCloseToAll(for: subscriptionID)
            }
        }
    }

    private func sendClose(from client: WebSocketClient, subscription: String) {
        do {
            let request: [Any] = ["CLOSE", subscription]
            let requestData = try JSONSerialization.data(withJSONObject: request)
            let requestString = String(data: requestData, encoding: .utf8)!
            client.write(string: requestString)
        } catch {
            Log.error("Error: Could not send close \(error.localizedDescription)")
        }
    }
    
    private func sendCloseToAll(for subscription: RelaySubscription.ID) async {
        await subscriptions.sockets.forEach { self.sendClose(from: $0, subscription: subscription) }
        Task { await processSubscriptionQueue() }
    }
    
    func closeConnection(to relayAddress: String?) async {
        guard let address = relayAddress else { return }
        if let socket = await subscriptions.socket(for: address) {
            for subscription in await subscriptions.active {
                self.sendClose(from: socket, subscription: subscription.id)
            }
            
            await subscriptions.close(socket: socket)
        }
    }
}

// MARK: Events
extension RelayService {
    
    /// Asks the service to start downloading events matching the given `filter` from relays and save them to Core 
    /// Data. If `specificRelays` are passed then those relays will be requested, otherwise we will use the user's list
    /// of preferred relays. Subscriptions are internally de-duplicated.
    /// 
    /// To close the subscription you can explicitly call `cancel()` on the returned `SubscriptionCancellable` or
    /// let it be deallocated.
    /// 
    /// - Parameter filter: an object describing the set of events you wish to fetch.
    /// - Parameter specificRelays: an optional list of relays you would like to fetch from. The user's preferred relays
    ///     will be used if this is not set.
    /// - Returns: A handle that allows the caller to cancel the subscription when it is no longer needed.     
    func subscribeToEvents(
        matching filter: Filter, 
        from specificRelays: [URL]? = nil
    ) async -> SubscriptionCancellable {
        var relayAddresses: [URL]
        if let specificRelays {
            relayAddresses = specificRelays
        } else {
            relayAddresses = await self.relayAddresses(for: currentUser)
        }
        if relayAddresses.isEmpty {
            // Fall back to a large list of relays if we don't have any for this user (like on first login)
            relayAddresses = Relay.allKnown.compactMap { URL(string: $0) }
        }
        var subscriptionIDs = [RelaySubscription.ID]()
        for relay in relayAddresses {
            subscriptionIDs.append(await subscriptions.queueSubscription(with: filter, to: relay))
        }
        
        // Fire off REQs in the background
        Task { await self.processSubscriptionQueue() }
        
        return SubscriptionCancellable(subscriptionIDs: subscriptionIDs, relayService: self)
    }
    
    /// Asks the relay to download a page of events matching the given `filter` from relays and save them to Core Data.
    /// You can cause the service to download the next page by calling `loadMore()` on the returned subscription object.
    /// The subscription will be cancelled when the returned subscription object is deallocated. 
    func subscribeToPagedEvents(matching filter: Filter) async -> PagedRelaySubscription {
        PagedRelaySubscription(
            startDate: .now, 
            filter: filter, 
            relayService: self,
            subscriptionManager: subscriptions, 
            relayAddresses: await self.relayAddresses(for: currentUser)
        )
    }
    
    func requestMetadata(for authorKey: RawAuthorID?, since: Date?) async -> SubscriptionCancellable {
        guard let authorKey else {
            return SubscriptionCancellable.empty()
        }
        
        let metaFilter = Filter(
            authorKeys: [authorKey],
            kinds: [.metaData],
            limit: 1, 
            since: since
        )
        return await subscribeToEvents(matching: metaFilter)
    }
    
    func requestContactList(for authorKey: RawAuthorID?, since: Date?) async -> SubscriptionCancellable {
        guard let authorKey else {
            return SubscriptionCancellable.empty()
        }
        
        let contactFilter = Filter(
            authorKeys: [authorKey],
            kinds: [.contactList],
            limit: 1,
            since: since
        )
        return await subscribeToEvents(matching: contactFilter)
    }
    
    func requestProfileData(
        for authorKey: RawAuthorID?, 
        lastUpdateMetadata: Date?, 
        lastUpdatedContactList: Date?
    ) async -> SubscriptionCancellable {
        var subscriptions = SubscriptionCancellables()
        guard let authorKey else {
            return SubscriptionCancellable.empty()
        }
        
        subscriptions.append(await requestMetadata(for: authorKey, since: lastUpdateMetadata))
        subscriptions.append(await requestContactList(for: authorKey, since: lastUpdatedContactList))
        
        return SubscriptionCancellable(cancellables: subscriptions, relayService: self)
    }
    
    /// Requests a single event from all relays
    func requestEvent(with eventID: String?) async -> SubscriptionCancellable {
        guard let eventID = eventID else {
            return SubscriptionCancellable.empty()
        }
        
        return await subscribeToEvents(matching: Filter(eventIDs: [eventID], limit: 1))
    }
    
    private func processSubscriptionQueue() async {
        await openSockets()
        await clearStaleSubscriptions()
        
        await subscriptions.processSubscriptionQueue()
        
        let socketsCount = await subscriptions.sockets.count
        Task { @MainActor in
            if numberOfConnectedRelays != socketsCount {
                numberOfConnectedRelays = socketsCount
            }
        }
    }
    
    private func clearStaleSubscriptions() async {
        let staleSubscriptions = await subscriptions.staleSubscriptions()
        for staleSubscription in staleSubscriptions {
            Log.debug("Subscription \(staleSubscription.id) is stale. Closing.")
            await sendCloseToAll(for: staleSubscription.id)
        }
    }
}

// MARK: Parsing
extension RelayService {
    private func parseEOSE(from socket: WebSocketClient, responseArray: [Any]) async {
        guard responseArray.count > 1 else {
            return
        }
        
        if let subID = responseArray[1] as? String,
            let subscription = await subscriptions.subscription(from: subID),
            subscription.isOneTime {
            Log.debug("\(socket.host) has finished responding on \(subID). Closing subscription.")
            // This is a one-off request. Close it.
            sendClose(from: socket, subscription: subID)
        }
    }
    
    private func queueEventForParsing(_ responseArray: [Any], _ socket: WebSocket) async {
        guard responseArray.count >= 3 else {
            Log.error("Error: invalid EVENT response: \(responseArray)")
            return
        }
        
        guard let eventJSON = responseArray[safe: 2] as? [String: Any],
            let subscriptionID = responseArray[safe: 1] as? RelaySubscription.ID else {
            Log.error("Error: invalid EVENT JSON: \(responseArray)")
            return
        }
        
        #if DEBUG
        // Log.debug("from \(socket.host): EVENT type: \(eventJSON["kind"] ?? "nil") subID: \(subscriptionID)")
        #endif

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: eventJSON)
            let jsonEvent = try JSONDecoder().decode(JSONEvent.self, from: jsonData)
            await self.parseQueue.push(jsonEvent, from: socket)
            
            if var subscription = await subscriptions.subscription(from: subscriptionID) {
                if let oldestSeen = subscription.oldestEventCreationDate,
                    jsonEvent.createdDate < oldestSeen {
                    subscription.oldestEventCreationDate = jsonEvent.createdDate
                    subscription.receivedEventCount += 1
                    await subscriptions.updateSubscriptions(with: subscription)
                } else {
                    subscription.oldestEventCreationDate = jsonEvent.createdDate
                    subscription.receivedEventCount += 1
                    await subscriptions.updateSubscriptions(with: subscription)
                }
                if subscription.isOneTime {
                    Log.debug("detected subscription with id \(subscription.id) has been fulfilled. Closing.")
                    await subscriptions.forceCloseSubscriptionCount(for: subscription.id)
                    await sendCloseToAll(for: subscription.id)
                }
            }
        } catch {
            print("Error: parsing event from relay (\(socket.request.url?.absoluteString ?? "")): " +
                "\(responseArray)\nerror: \(error.localizedDescription)")
        }
    }
    
    /// Processes a batch of events from the queue. Returns false if there were no events to process.
    private func batchParseEvents() async throws -> Bool {
        let eventData = await self.parseQueue.pop(30)
        if eventData.isEmpty {
            return false
        } else {
            let remainingEventCount = await parseQueue.count
            try await self.parseContext.perform {
                var savedEvents = 0
                for (event, socket) in eventData {
                    let relay = self.relay(from: socket, in: self.parseContext)
                    do {
                        if try EventProcessor.parse(jsonEvent: event, from: relay, in: self.parseContext) != nil {
                            savedEvents += 1
                        }
                    } catch {
                        Log.error("RelayService: Error parsing event \(event.id): \(error.localizedDescription)")
                    }
                }
                #if DEBUG
                Log.debug(
                    "Parsed \(eventData.count) events and saved \(savedEvents) to database. " +
                    "\(remainingEventCount) events left in parse queue."
                )
                #endif
                try self.parseContext.saveIfNeeded()
            }                
            return true
        }
    }

    private func parseOK(_ responseArray: [Any], _ socket: WebSocket) async {
        guard responseArray.count > 2 else {
            return
        }
        
        if let success = responseArray[2] as? Bool,
            let eventId = responseArray[1] as? String,
            let socketUrl = socket.request.url?.absoluteString {
            
            await backgroundContext.perform {
                
                if let event = Event.find(by: eventId, context: self.backgroundContext),
                    let relay = self.relay(from: socket, in: self.backgroundContext) {
                    
                    if success {
                        print("\(eventId) has published successfully to \(socketUrl)")
                        event.publishedTo.insert(relay)
                        
                        // Receiving a confirmation of my own deletion event
                        do {
                            try event.trackDelete(on: relay, context: self.backgroundContext)
                        } catch {
                            Log.error(error.localizedDescription)
                        }
                    } else {
                        // This will be picked up later in publishFailedEvents
                        if responseArray.count > 2, let message = responseArray[3] as? String {
                            // Mark duplicates or replaces as done on our end
                            if message.contains("replaced:") || message.contains("duplicate:") {
                                event.publishedTo.insert(relay)
                            } else {
                                print("\(eventId) has been rejected. Given reason: \(message)")
                            }
                        } else {
                            print("\(eventId) has been rejected. No given reason.")
                        }
                    }
                    
                    try? self.backgroundContext.saveIfNeeded()
                } else {
                    print("Error: got OK for missing Event: \(eventId)")
                }
            }
        }
    }
    
    private func parseNotice(from socket: WebSocket, responseArray: [Any]) {
        let response = responseArray.description 
        Log.debug("Notice from \(socket.host): \(response)")
        if let notice = responseArray[safe: 1] as? String {
            if notice == "rate limited" {
                analytics.rateLimited(by: socket)
            } else if notice.contains("bad req:") {
                analytics.badRequest(from: socket, message: response)
            }
        }
    }
    
    private func parseResponse(_ response: String, _ socket: WebSocket) async {
        
        do {
            guard let responseData = response.data(using: .utf8) else {
                throw EventError.utf8Encoding
            }
            let jsonResponse = try JSONSerialization.jsonObject(with: responseData)
            guard let responseArray = jsonResponse as? [Any],
                let responseType = responseArray.first as? String else {
                print("Error: got unparseable response: \(response)")
                return
            }
            
            switch responseType {
            case "EVENT":
                await queueEventForParsing(responseArray, socket)
            case "NOTICE":
                parseNotice(from: socket, responseArray: responseArray)
            case "EOSE":
                await parseEOSE(from: socket, responseArray: responseArray)
            case "OK":
                await parseOK(responseArray, socket)
            default:
                print("got unknown response type: \(response)")
            }
        } catch {
            print("error parsing response: \(response)\nerror: \(error.localizedDescription)")
        }
    }
}

// MARK: Publish
extension RelayService {
    
    private func publish(from client: WebSocketClient, jsonEvent: JSONEvent) async throws {
        // Keep track of this so if it fails we can retry N times
        let requestString = try jsonEvent.buildPublishRequest()
        Log.info("publishing \(requestString)")
        client.write(string: requestString)
    }
    
    /// Opens a websocket and writes a single message to it. On failure this function will just log the error to the 
    /// console.
    private func openSocket(to url: URL, andSend message: String) async {
        var urlRequest = URLRequest(url: url)
        urlRequest.timeoutInterval = 10
        let socket = WebSocket(request: urlRequest, compressionHandler: .none)
        
        // Make sure the socket doesn't stay open too long
        _ = Task(timeout: 10) { socket.disconnect() }
        return await withCheckedContinuation({ continuation in
            socket.onEvent = { (event: WebSocketEvent) in
                switch event {
                case WebSocketEvent.connected:
                    socket.write(string: message)
                    socket.disconnect()
                case WebSocketEvent.disconnected:
                    continuation.resume()
                case WebSocketEvent.error(let error):
                    Log.optional(error, "failed to send message: \(message) to websocket")
                default:
                    return
                }
            }
            socket.connect()
        })
    }

    func publishToAll(event: JSONEvent, signingKey: KeyPair, context: NSManagedObjectContext) async throws {
        await self.openSockets()
        let signedEvent = try await signAndSave(event: event, signingKey: signingKey, in: context)
        for socket in await subscriptions.sockets {
            try await publish(from: socket, jsonEvent: signedEvent)
        }
    }

    func publish(
        event: JSONEvent,
        to relayURLs: [URL],
        signingKey: KeyPair,
        context: NSManagedObjectContext
    ) async throws {
        await openSockets()
        let signedEvent = try await signAndSave(event: event, signingKey: signingKey, in: context)
        for relayURL in relayURLs {
            if let socket = await socket(from: relayURL) {
                try await publish(from: socket, jsonEvent: signedEvent)
            } else {
                Log.error("Could not find socket to publish message")
            }
        }
    }
    
    func publish(
        event: JSONEvent,
        to relayURL: URL,
        signingKey: KeyPair? = nil,
        context: NSManagedObjectContext
    ) async throws {
        var signedEvent: JSONEvent

        switch signingKey {
        case .none:
            // If you don't provide a key, the event needs to be already signed
            guard !event.signature.isEmptyOrNil else {
                Log.error("Missing signature and no key provided for event \(event)")
                throw RelayError.missingSignatureOrKey
            }
            
            signedEvent = event

        case .some(let keyPair):
            signedEvent = try await signAndSave(event: event, signingKey: keyPair, in: context)
        }

        await openSocket(to: relayURL, andSend: try signedEvent.buildPublishRequest())
    }
    
    private func signAndSave(
        event: JSONEvent,
        signingKey: KeyPair,
        in context: NSManagedObjectContext
    ) async throws -> JSONEvent {
        var jsonEvent = event
        
        // Should we throw if the event is already signed? this way we can ensure that we
        // don't sign events multiple times, it's costly and it would be easy to do it
        // inadvertently.
        try jsonEvent.sign(withKey: signingKey)
        
        try await context.perform {
            guard let event = try EventProcessor.parse(jsonEvent: jsonEvent, from: nil, in: context) else {
                Log.error("Could not parse new event \(jsonEvent)")
                throw RelayError.parseError
            }
            let relays = try context.fetch(Relay.relays(for: event.author!))
            event.shouldBePublishedTo = Set(relays)
            try context.save()
        }
        
        return jsonEvent
    }
    
    @MainActor func publishFailedEvents() async {
        guard let userKey = currentUser.author?.hexadecimalPublicKey else {
            return
        }
        
        await self.backgroundContext.perform {
            
            guard let user = try? Author.find(by: userKey, context: self.backgroundContext) else {
                return
            }
            let objectContext = self.backgroundContext
            let userSentEvents = Event.unpublishedEvents(for: user, context: objectContext)
            
            for event in userSentEvents {
                let missedRelays = event.shouldBePublishedTo.subtracting(event.publishedTo)
                
                print("\(missedRelays.count) relays missing a published event.")
                for missedRelay in missedRelays {
                    guard let missedAddress = missedRelay.address, let jsonEvent = event.codable else { continue }
                    Task {
                        if let socket = await self.subscriptions.socket(for: missedAddress) {
                            // Publish again to this socket
                            print("Republishing \(jsonEvent.id) on \(missedAddress)")
                            do {
                                try await self.publish(from: socket, jsonEvent: jsonEvent)
                            } catch {
                                Log.error(error.localizedDescription)
                            }
                        }
                    }
                }
            }
            
            try? self.backgroundContext.saveIfNeeded()
        }
    }
    
    func deleteExpiredEvents() async {
        await self.backgroundContext.perform {
            do {
                for event in try self.backgroundContext.fetch(Event.expiredRequest()) {
                    self.backgroundContext.delete(event)
                }
                try self.backgroundContext.saveIfNeeded()
            } catch {
                Log.error("Error fetching expired events \(error.localizedDescription)")
            }
        }
    }
}

// MARK: Sockets
extension RelayService {
    /// Opens sockets to all the relays that we have an open subscription for.
    @MainActor private func openSockets() async {
        let relayAddresses = Set(await subscriptions.all.map { $0.relayAddress })
        
        for relayAddress in relayAddresses {
            guard let socket = await subscriptions.addSocket(for: relayAddress) else {
                continue
            }
            socket.callbackQueue = processingQueue
            socket.delegate = self
            socket.connect()
            Task.detached(priority: .background) {
                do {
                    try await self.queryRelayMetadataIfNeeded(relayAddress)
                } catch {
                    Log.optional(error)
                }
            }
        }
    }

    func relayAddresses(for user: CurrentUser) async -> [URL] {
        await backgroundContext.perform { () -> [URL] in
            if let currentUserPubKey = user.publicKeyHex,
                let currentUser = try? Author.find(by: currentUserPubKey, context: self.backgroundContext) {
                let userRelays = currentUser.relays
                return userRelays.compactMap { $0.addressURL }
            } else {
                return []
            }
        }
    }

    private func queryRelayMetadataIfNeeded(_ relayAddress: URL) async throws {
        let address = relayAddress.absoluteString
        let shouldQueryRelayMetadata = try await backgroundContext.perform { [backgroundContext] in
            guard let relay = try backgroundContext.fetch(Relay.relay(by: address)).first else {
                return false
            }
            guard let timestamp = relay.metadataFetchedAt else {
                return true
            }
            return timestamp.timeIntervalSinceNow > 86_400 * 3 // 3 days
        }
        guard shouldQueryRelayMetadata else {
            return
        }
        guard var components = URLComponents(url: relayAddress, resolvingAgainstBaseURL: true) else {
            return
        }
        components.scheme = "https"
        guard let url = components.url else {
            return
        }
        var request = URLRequest(url: url)
        request.addValue("application/nostr+json", forHTTPHeaderField: "Accept")
        let session = URLSession(configuration: .ephemeral)
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            return
        }
        guard httpResponse.statusCode == 200 else {
            return
        }
        let decoder = JSONDecoder()
        let metadata = try decoder.decode(JSONRelayMetadata.self, from: data)

        try await backgroundContext.perform { [backgroundContext] in
            guard let relay = try backgroundContext.fetch(Relay.relay(by: address)).first else {
                return
            }
            try relay.hydrate(from: metadata)
            try backgroundContext.saveIfNeeded()
        }
    }

    private func handleConnection(from client: WebSocketClient) async {
        if let socket = client as? WebSocket {
            Log.debug("websocket is connected: \(String(describing: socket.request.url?.host))")
        } else {
            Log.error("websocket connected with unknown host")
        }
        
        for subscription in await subscriptions.active where subscription.relayAddress == client.url {
            await subscriptions.requestEvents(from: client, subscription: subscription)
        }
    }
}

// MARK: WebSocketDelegate
extension RelayService: WebSocketDelegate {
    func didReceive(event: WebSocketEvent, client: WebSocketClient) {
        guard let socket = client as? WebSocket else {
            return
        }
        
        Task {
            switch event {
            case .connected:
                await handleConnection(from: client)
            case .viabilityChanged(let isViable) where isViable:
                await handleConnection(from: client)
            case .disconnected(let reason, let code):
                await subscriptions.remove(socket)
                print("websocket is disconnected: \(reason) with code: \(code)")
            case .text(let string):
                await parseResponse(string, socket)
            case .binary:
                break
            case .ping, .pong, .viabilityChanged, .reconnectSuggested, .peerClosed:
                break
            case .cancelled:
                await subscriptions.remove(socket)
                print("websocket is cancelled")
            case .error(let error):
                await subscriptions.remove(socket)
                handleError(error, from: socket)
            }
        }
    }
}

// MARK: NIP-05 and UNS Support
extension RelayService {

    /// Takes a NIP-05 or Mastodon username and tries to fetch the associated Nostr public key.
    func retrievePublicKeyFromUsername(_ userName: String) async -> RawAuthorID? {
        let count = userName.filter { $0 == "@" }.count
        
        switch count {
        case 1:
            return try? await fetchPublicKeyFromNIP05(userName)
        case 2:
            return try? await fetchPublicKeyFromMastodonUsername(userName)
        default:
            return nil
        }
    }

    func fetchPublicKeyFromNIP05(_ nip05: String) async throws -> String? {
        guard let (localPart, domain) = parseNIP05(from: nip05) else {
            return nil
        }
        
        let urlString = "https://\(domain)/.well-known/nostr.json?name=\(localPart)"
        return try await fetchPublicKey(from: urlString, username: localPart)
    }

    func fetchPublicKeyFromMastodonUsername(_ mastodonUsername: String) async throws -> RawAuthorID? {
        guard let mostrUsername = mostrUsername(from: mastodonUsername) else {
            return nil
        }
        
        let urlString = "https://mostr.pub/.well-known/nostr.json?name=\(mostrUsername)"
        return try await fetchPublicKey(from: urlString, username: mostrUsername)
    }

    func fetchPublicKey(from nip05URL: String, username: String) async throws -> String? {
        guard let url = URL(string: nip05URL) else {
            Log.info("Invalid URL: \(nip05URL)")
            return nil
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        return (json?["names"] as? [String: String])?[username]
    }

    func parseNIP05(from identifier: String) -> (localPart: String, domain: String)? {
        let components = identifier.components(separatedBy: "@")
        guard components.count == 2, let localPart = components.first, let domain = components.last else {
            return nil
        }
        return (localPart, domain)
    }

    func mostrUsername(from mastodonUsername: String) -> String? {
        guard mastodonUsername.filter({ $0 == "@" }).count == 2 else {
            Log.info("Invalid Mastodon username format.")
            return nil
        }
        
        let withoutFirstAt = String(mastodonUsername.dropFirst())
        return withoutFirstAt.replacingOccurrences(
            of: "@", 
            with: "_at_", 
            options: [], 
            range: withoutFirstAt.range(of: "@")
        )
    }

    func relay(from socket: WebSocket, in context: NSManagedObjectContext) -> Relay? {
        guard let socketURL = socket.request.url else {
            Log.error("Got socket with no URL: \(socket.request)")
            return nil
        }
        do {
            return try Relay.findOrCreate(by: socketURL.absoluteString, context: context)
        } catch {
            Log.error(error.localizedDescription)
            return nil
        }
    }
    
    func socket(from url: URL?) async -> WebSocket? {
        guard let url else { return nil }
        return await subscriptions.socket(for: url)
    }

    func unsURL(from unsIdentifier: String) -> URL? {
        let urlString = "https://universalname.space/profile/\(unsIdentifier)"
        guard let url = URL(string: urlString) else { return nil }
        return url
    }
}

// swiftlint:enable file_length
