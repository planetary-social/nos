import Foundation
import Starscream
import CoreData
import Logger
import Dependencies
import UIKit

// swiftlint:disable file_length

/// A service that maintains connections to Nostr Relay servers and executes requests for data from those relays
/// in the form of `Filters` and `RelaySubscription`s.
@Observable class RelayService {
    
    private var subscriptionManager: RelaySubscriptionManager
    private var processSubscriptionQueueTimer: AsyncTimer?
    private var backgroundProcessTimer: AsyncTimer?
    private var eventProcessingLoop: Task<Void, Error>?
    private var backgroundContext: NSManagedObjectContext
    private var processingQueue = DispatchQueue(label: "RelayService-processing", qos: .userInitiated)
    private var parseQueue = ParseQueue()
    
    @ObservationIgnored @Dependency(\.persistenceController) var persistenceController
    @ObservationIgnored @Dependency(\.analytics) private var analytics
    @ObservationIgnored @Dependency(\.crashReporting) private var crashReporting
    @MainActor @ObservationIgnored @Dependency(\.currentUser) private var currentUser
    
    init(subscriptionManager: RelaySubscriptionManager = RelaySubscriptionManagerActor()) {
        self.subscriptionManager = subscriptionManager
        @Dependency(\.persistenceController) var persistenceController
        self.backgroundContext = persistenceController.newBackgroundContext()
        
        Task { await self.subscriptionManager.set(socketQueue: processingQueue, delegate: self) }
        
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
            await self?.retryFailedPublishes()
            await self?.deleteExpiredEvents()
        })
        
        Task { @MainActor in
            currentUser.viewContext = persistenceController.viewContext
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
        Task { await subscriptionManager.processSubscriptionQueue() }
    }
    
    private func handleError(_ error: Error?, from socket: WebSocketClient) {
        if let error {
            Log.debug("websocket error: \(error) from: \(socket.host)")
        } else {
            Log.debug("unknown websocket error from: \(socket.host)")
        }
    }
}

// MARK: Closing subscriptions
extension RelayService {
    
    func decrementSubscriptionCount(for subscriptionIDs: [String]) {
        for subscriptionID in subscriptionIDs {
            self.decrementSubscriptionCount(for: subscriptionID)
        }
    }
    
    func decrementSubscriptionCount(for subscriptionID: String) {
        Task {
            let subscriptionStillActive = await subscriptionManager.decrementSubscriptionCount(for: subscriptionID)
            if !subscriptionStillActive {
                await self.sendCloseToAll(for: subscriptionID)
            }
        }
    }
    
    private func sendClose(from client: WebSocketClient, subscriptionID: RelaySubscription.ID) async {
        do {
            await subscriptionManager.forceCloseSubscriptionCount(for: subscriptionID)
            let request: [Any] = ["CLOSE", subscriptionID]
            let requestData = try JSONSerialization.data(withJSONObject: request)
            let requestString = String(decoding: requestData, as: UTF8.self)
            client.write(string: requestString)
        } catch {
            Log.error("Error: Could not send close \(error.localizedDescription)")
        }
    }
    
    private func sendCloseToAll(for subscription: RelaySubscription.ID) async {
        let sockets = await subscriptionManager.sockets()
        for socket in sockets {
            await self.sendClose(from: socket, subscriptionID: subscription) 
        }
        Task { await processSubscriptionQueue() }
    }
    
    func closeConnection(to relayAddress: String?) async {
        guard let address = relayAddress else { return }
        if let socket = await subscriptionManager.socket(for: address) {
            for subscription in await subscriptionManager.active() {
                await self.sendClose(from: socket, subscriptionID: subscription.id)
            }
            
            await subscriptionManager.close(socket: socket)
        }
    }
}

// MARK: Fetching Events
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
    @discardableResult func fetchEvents(
        matching filter: Filter,
        from specificRelays: [URL]? = nil
    ) async -> SubscriptionCancellable {
        var relayAddresses: Set<URL>
        if let specificRelays {
            relayAddresses = Set(specificRelays)
        } else {
            relayAddresses = await self.relayAddresses(for: currentUser)
        }
        if relayAddresses.isEmpty {
            // Fall back to a large list of relays if we don't have any for this user (like on first login)
            relayAddresses = Set(Relay.allKnown.compactMap { URL(string: $0) })
        }
        var subscriptionIDs = [RelaySubscription.ID]()
        for relay in relayAddresses {
            subscriptionIDs.append(await subscriptionManager.queueSubscription(with: filter, to: relay).id)
        }
        
        // Fire off REQs in the background
        Task { await self.processSubscriptionQueue() }
        
        return SubscriptionCancellable(subscriptionIDs: subscriptionIDs, relayService: self)
    }
    
    /// Asks the relay to download a page of events matching the given `filter` from relays and save them to Core Data.
    /// You can cause the service to download the next page by calling `loadMore()` on the returned subscription object.
    /// The subscription will be cancelled when the returned subscription object is deallocated.
    /// - Parameters:
    ///   - filter: an object describing the set of events that should be downloaded.
    ///   - specificRelay: a specific relay to download events from. If `nil` the user's relay list will be used.
    /// - Returns: A handle that can be used to load more pages of events. It will close the relay subscriptions
    ///     when deallocated.
    func subscribeToPagedEvents(
        matching filter: Filter, 
        from specificRelay: URL? = nil
    ) async -> PagedRelaySubscription {
        var relays = Set<URL>()
        if let specificRelay {
            relays.insert(specificRelay)
        } else {
            relays = await self.relayAddresses(for: currentUser)
        }
        
        return await PagedRelaySubscription(
            startDate: .now,
            filter: filter,
            relayService: self,
            subscriptionManager: subscriptionManager,
            relayAddresses: relays
        )
    }
    
    func requestReplyFromAnyone(for eventID: RawEventID?) async -> SubscriptionCancellable {
        guard let eventID else {
            return SubscriptionCancellable.empty()
        }
        let metaFilter = Filter(
            kinds: [.text],
            eTags: [eventID],
            limit: 1
        )
        return await fetchEvents(matching: metaFilter)
    }

    /// Builds a subscription that fetched replies from follows to the given
    /// event.
    ///
    /// - Parameter eventID: A note identifier.
    /// - Parameter limit: Maximum number of replies to ask for. Defaults to
    /// nil (no limit).
    func requestRepliesFromFollows(
        for eventID: RawEventID?,
        limit: Int? = nil
    ) async -> SubscriptionCancellable {
        guard let eventID else {
            return SubscriptionCancellable.empty()
        }
        let metaFilter = Filter(
            authorKeys: Array(await currentUser.socialGraph.followedKeys),
            kinds: [.text],
            eTags: [eventID],
            limit: limit
        )
        return await fetchEvents(matching: metaFilter)
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
        return await fetchEvents(matching: metaFilter)
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
        return await fetchEvents(matching: contactFilter)
    }
    
    func requestAuthorLists(
        for authorKey: RawAuthorID?,
        since: Date?
    ) async -> SubscriptionCancellable {
        guard let authorKey else {
            return SubscriptionCancellable.empty()
        }
        
        let followSetFilter = Filter(
            authorKeys: [authorKey],
            kinds: [.followSet],
            since: since
        )
        return await fetchEvents(matching: followSetFilter)
    }
    
    func requestProfileData(
        for authorKey: RawAuthorID?,
        lastUpdateMetadata: Date?,
        lastUpdatedContactList: Date?,
        lastUpdatedFollowSets: Date?
    ) async -> SubscriptionCancellable {
        var subscriptions = SubscriptionCancellables()
        guard let authorKey else {
            return SubscriptionCancellable.empty()
        }
        
        subscriptions.append(await requestMetadata(for: authorKey, since: lastUpdateMetadata))
        subscriptions.append(await requestContactList(for: authorKey, since: lastUpdatedContactList))
        subscriptions.append(await requestAuthorLists(for: authorKey, since: lastUpdatedFollowSets))

        return SubscriptionCancellable(cancellables: subscriptions, relayService: self)
    }
    
    /// Requests a single event from all relays
    func requestEvent(with eventID: String?) async -> SubscriptionCancellable {
        guard let eventID = eventID else {
            return SubscriptionCancellable.empty()
        }
        
        return await fetchEvents(
            matching: Filter(
                eventIDs: [eventID],
                limit: 1
            )
        )
    }
    
    func requestEvent(with replaceableID: RawReplaceableID?, authorKey: RawAuthorID) async -> SubscriptionCancellable {
        guard let replaceableID else {
            return SubscriptionCancellable.empty()
        }
        
        return await fetchEvents(matching: Filter(authorKeys: [authorKey], dTags: [replaceableID], limit: 1))
    }
    
    private func processSubscriptionQueue() async {
        await clearStaleSubscriptions()
        
        await subscriptionManager.processSubscriptionQueue()
    }
    
    private func clearStaleSubscriptions() async {
        let staleSubscriptions = await subscriptionManager.staleSubscriptions()
        for staleSubscription in staleSubscriptions {
            await sendCloseToAll(for: staleSubscription.id)
        }
    }
}

// MARK: Parsing Events

extension RelayService {
    private func parseEOSE(from socket: WebSocketClient, responseArray: [Any]) async {
        guard responseArray.count > 1 else {
            return
        }
        
        if let subID = responseArray[1] as? String,
            let subscription = await subscriptionManager.subscription(from: subID),
            subscription.closesAfterResponse {
            // This is a one-off request. Close it.
            await sendClose(from: socket, subscriptionID: subID)
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
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: eventJSON)
            let jsonEvent = try JSONDecoder().decode(JSONEvent.self, from: jsonData)
            if jsonEvent.kind == 20 {
                Log.info("Received picture-first event (kind 20) from \(socket.request.url?.absoluteString ?? \"unknown relay\")")
            }
            await self.parseQueue.push(jsonEvent, from: socket)
            
            if let subscription = await subscriptionManager.subscription(from: subscriptionID) {
                subscription.receivedEventCount += 1
                subscription.events.send(jsonEvent)
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
            let keyPair = await currentUser.keyPair
            try await persistenceController.parseContext.perform {
                var savedEvents = 0
                for (event, socket) in eventData {
                    let relay = self.relay(from: socket, in: self.persistenceController.parseContext)
                    do {
                        let context = self.persistenceController.parseContext
                        if try EventProcessor.parse(
                            jsonEvent: event,
                            from: relay,
                            in: context,
                            keyPair: keyPair
                        ) != nil {
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
                if remainingEventCount >= 1000 && remainingEventCount < 1030 {
                    self.crashReporting.report("Parse queue is large: currently 1000+ events")
                }
                try self.persistenceController.parseContext.saveIfNeeded()
                try self.persistenceController.viewContext.saveIfNeeded()
            }
            return true
        }
    }
}

// MARK: Relay Communication
extension RelayService {
    
    private func parseOK(_ responseArray: [Any], _ socket: WebSocket) async {
        guard responseArray.count > 2 else {
            return
        }
        
        if let success = responseArray[2] as? Bool,
            let eventID = responseArray[1] as? String,
            let socketURL = socket.request.url?.absoluteString {
            
            let isAuthMessage = await subscriptionManager.checkAuthentication(
                success: success, 
                from: socket, 
                eventID: eventID, 
                message: responseArray[3] as? String
            )
            if isAuthMessage {
                return
            }
            
            await backgroundContext.perform {
                
                if let event = Event.find(by: eventID, context: self.backgroundContext),
                    let relay = self.relay(from: socket, in: self.backgroundContext) {
                    
                    if success {
                        Log.info("\(eventID) has published successfully to \(socketURL)")
                        event.publishedTo.insert(relay)
                        
                        // Receiving a confirmation of my own deletion event
                        do {
                            try event.trackDelete(on: relay, context: self.backgroundContext)
                        } catch {
                            Log.error(error.localizedDescription)
                        }
                    } else {
                        // This will be picked up later in retryFailedPublishes()
                        if responseArray.count > 2, let message = responseArray[3] as? String {
                            // Mark duplicates or replaces as done on our end
                            if message.contains("replaced:") || message.contains("duplicate:") {
                                event.publishedTo.insert(relay)
                            } else {
                                Log.info("Event \(eventID) has been rejected by \(socketURL). Given reason: \(message)")
                            }
                        } else {
                            Log.info("Event \(eventID) has been rejected by \(socketURL). No given reason.")
                        }
                    }
                    
                    try? self.backgroundContext.saveIfNeeded()
                } else {
                    Log.error("Error: got OK for missing Event: \(eventID)")
                }
            }
        }
    }
    
    private func parseNotice(from socket: WebSocket, responseArray: [Any]) {
        let response = responseArray.description
        Log.debug("Notice from \(socket.host): \(response)")
        if let notice = responseArray[safe: 1] as? String {
            if notice == "rate limited" || notice == "ERROR: too many concurrent REQs" {
                Task {
                    let numberOfRequests = await subscriptionManager.active()
                        .filter { subscription in
                            subscription.relayAddress == socket.url
                        }
                        .count
                    analytics.rateLimited(by: socket, requestCount: numberOfRequests)
                }
            } else if notice.contains("bad req:") {
                analytics.badRequest(from: socket, message: response)
            }
        }
    }
    
    private func handleClosed(from socket: WebSocket, responseArray: [Any]) async {
        if let subID = responseArray[safe: 1] as? RelaySubscription.ID {
            await subscriptionManager.receivedClose(for: subID, from: socket)
        }
    }
    
    /// Handles "AUTH" messages from the relay, responding with the appropriate challenge.
    private func handleAuthentication(from socket: WebSocket, responseArray: [Any]) async {
        guard responseArray.count >= 2,
            let challenge = responseArray[safe: 1] as? String,
            let userKeyPair = await currentUser.keyPair,
            let relayAddress = socket.url else {
            return
        }
        
        var jsonEvent = JSONEvent(
            pubKey: userKeyPair.publicKeyHex, 
            kind: .relayAuth, 
            tags: [
                ["relay", socket.url?.absoluteString ?? ""],
                ["challenge", challenge]
            ], 
            content: ""
        )
        
        do {
            let identifier = try jsonEvent.calculateIdentifier()
            await subscriptionManager.trackAuthenticationRequest(from: socket, responseID: identifier) 
            try jsonEvent.sign(withKey: userKeyPair)
            
            let request: [Any] = ["AUTH", jsonEvent.dictionary]
            let requestData = try JSONSerialization.data(withJSONObject: request)
            let string = String(decoding: requestData, as: UTF8.self)
            socket.write(string: string)
        } catch {
            Log.error("Error authenticating with \(relayAddress)", error.localizedDescription)
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
                Log.info(
                    "got unparseable response from \(String(describing: socket.url?.absoluteString)): \(jsonResponse)"
                )
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
            case "AUTH":
                await handleAuthentication(from: socket, responseArray: responseArray)
            case "CLOSED":
                await handleClosed(from: socket, responseArray: responseArray)
            default:
                Log.info("got unhandled response from \(String(describing: socket.url?.absoluteString)): \(response)")
            }
        } catch {
            Log.info(
                "error parsing response from \(String(describing: socket.url?.absoluteString)): " + 
                "\(error.localizedDescription)"
            )
        }
    }
}

// MARK: Publish
extension RelayService {
    
    private func publish(from client: WebSocketClient, jsonEvent: JSONEvent) async throws {
        // Keep track of this so if it fails we can retry N times
        let requestString = try jsonEvent.buildPublishRequest()
        client.write(string: requestString)
    }
    
    /// Opens a websocket and writes a single message to it. On failure this function will just log the error to the
    /// console.
    private func openSocket(to url: URL, andSend message: String) async {
        var urlRequest = URLRequest(url: url)
        urlRequest.timeoutInterval = 10
        let socket = WebSocket(request: urlRequest, compressionHandler: .none)
        
        let timeoutTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(10 * 1_000_000_000))
            Log.info("Socket to \(url.absoluteString) timed out, disconnecting")
            socket.disconnect()
        }
        
        return await withCheckedContinuation({ [weak socket] continuation in
            var written = false
            var continued = false
            
            socket?.onEvent = { [weak socket] (event: WebSocketEvent) in
                switch event {
                case WebSocketEvent.connected:
                    if !written {
                        socket?.write(string: message, completion: {
                            written = true
                        })
                    }
                case WebSocketEvent.text(let text):
                    if written {
                        Log.info("Received \(text) after write, disconnecting")
                        socket?.disconnect()
                    }
                case WebSocketEvent.viabilityChanged(let isViable) where isViable:
                    if !written {
                        socket?.write(string: message, completion: {
                            written = true
                        })
                    }
                case WebSocketEvent.error(let error):
                    Log.optional(error, "failed to send message: \(message) to websocket")
                    socket?.disconnect()
                case WebSocketEvent.disconnected, WebSocketEvent.cancelled:
                    timeoutTask.cancel()
                    if !continued {
                        continuation.resume()
                        continued = true
                    }
                    
                // For the rest of the messages, we just ignore and wait
                default:
                    return
                }
            }
            
            socket?.connect()
        })
    }
    
    @discardableResult
    func publishToAll(
        event: JSONEvent, 
        signingKey: KeyPair, 
        context: NSManagedObjectContext
    ) async throws -> JSONEvent {
        let signedEvent = try await signAndSave(event: event, signingKey: signingKey, in: context)
        for socket in await subscriptionManager.sockets() {
            try await publish(from: socket, jsonEvent: signedEvent)
        }
        return signedEvent
    }
    
    func publish(
        event: JSONEvent,
        to relayURLs: [URL],
        signingKey: KeyPair,
        context: NSManagedObjectContext
    ) async throws {
        let signedEvent = try await signAndSave(event: event, signingKey: signingKey, relayURLs: relayURLs, in: context)
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
        let signedEvent: JSONEvent
        
        if let signingKey {
            signedEvent = try await signAndSave(
                event: event,
                signingKey: signingKey,
                relayURLs: [relayURL],
                in: context
            )
        } else {
            // If you don't provide a key, the event needs to be already signed
            guard !event.signature.isEmptyOrNil else {
                Log.error("Missing signature and no key provided for event \(event)")
                throw RelayError.missingSignatureOrKey
            }
            
            signedEvent = event
        }
        
        await openSocket(to: relayURL, andSend: try signedEvent.buildPublishRequest())
    }
    
    private func signAndSave(
        event: JSONEvent,
        signingKey: KeyPair,
        relayURLs: [URL]? = nil,
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
            let relays: [Relay]
            if let relayURLs {
                relays = try relayURLs.map { try Relay.findOrCreate(by: $0.absoluteString, context: context) }
            } else {
                relays = try context.fetch(Relay.relays(for: event.author!))
            }
            event.shouldBePublishedTo = Set(relays)
            try context.save()
        }
        
        return jsonEvent
    }
    
    /// This function is meant to be run periodically to try to publish events that failed to publish in the past. It
    /// uses the `shouldBePublishedTo` and `publishedTo` relationships on `Event` to determine what failed to publish.
    /// These events could have failed to publish becuase the relay was offline, or because the user was offline. Often 
    /// the user has relay in their list that they don't have write access to so eventually this function will stop
    /// trying to republish the same event.
    @MainActor private func retryFailedPublishes() async {
        guard let userKey = currentUser.author?.hexadecimalPublicKey else {
            return
        }
        
        await backgroundContext.perform {
            
            guard let user = try? Author.find(by: userKey, context: self.backgroundContext) else {
                return
            }
            let objectContext = self.backgroundContext
            let eventsToRetry = Event.unpublishedEvents(for: user, context: objectContext)
            
            // Try to publish each of these again to each relay that failed.
            for event in eventsToRetry {
                guard let jsonEvent = event.codable else { continue }
                
                let missedRelays = event.shouldBePublishedTo.subtracting(event.publishedTo)
                let missedAddresses = missedRelays.compactMap { $0.address }
                
                for missedAddress in missedAddresses {
                    Task {
                        if let socket = await self.subscriptionManager.socket(for: missedAddress) {
                            // Publish again to this socket
                            Log.info("Retrying publish of event \(jsonEvent.id) to \(missedAddress)")
                            do {
                                try await self.publish(from: socket, jsonEvent: jsonEvent)
                            } catch {
                                Log.error(error.localizedDescription)
                            }
                        }
                    }
                }
            }
            
            // Don't try again if the event is more than five days old
            let fiveDays: TimeInterval = 60 * 60 * 24 * 5
            let now = Date.now.timeIntervalSince1970
            for event in eventsToRetry {
                let publishDate = event.createdAt?.timeIntervalSince1970 ?? 0
                if now - publishDate > fiveDays {
                    Log.info("Done retrying publish for event \(String(describing: event.identifier))")
                    event.shouldBePublishedTo = Set()
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

    func relayAddresses(for user: CurrentUser) async -> Set<URL> {
        await backgroundContext.perform { () -> Set<URL> in
            if let currentUserPubKey = user.publicKeyHex,
                let currentUser = try? Author.find(by: currentUserPubKey, context: self.backgroundContext) {
                let userRelays = Set(currentUser.relays.compactMap { $0.addressURL })
                
                // Remove search only relays
                let filteredRelays = userRelays.filter { relayAddress in
                    guard let host = relayAddress.host(percentEncoded: true) else { return true }
                    return !host.hasSuffix(".nostr.band")
                }
                
                return filteredRelays
            } else {
                return Set()
            }
        }
    }
    
    private func queryRelayMetadataIfNeeded(_ relayAddress: URL) async throws {
        let metadataMaxAge: TimeInterval = 86_400 * 3 // 3 days
        let address = relayAddress.absoluteString
        let shouldQueryRelayMetadata = try await backgroundContext.perform { [backgroundContext] in
            guard let relay = try backgroundContext.fetch(Relay.relay(by: address)).first else {
                return false
            }
            guard let timestamp = relay.metadataFetchedAt else {
                return true
            }
            return Date.now.timeIntervalSince(timestamp) > metadataMaxAge
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
            await subscriptionManager.trackConnected(socket: socket)
            Task.detached(priority: .background) {
                do {
                    if let url = client.url {
                        try await self.queryRelayMetadataIfNeeded(url)
                    }
                } catch {
                    Log.optional(error)
                }
            }
        } else {
            Log.error("websocket connected with unknown host")
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
            case .connected, .viabilityChanged(true):
                await handleConnection(from: client)
            case .disconnected:
                await subscriptionManager.trackError(socket: socket)
            case .peerClosed:
                await subscriptionManager.trackError(socket: socket)
            case .text(let string):
                await parseResponse(string, socket)
            case .binary:
                break
            case .ping, .pong, .viabilityChanged, .reconnectSuggested:
                break
            case .cancelled:
                await subscriptionManager.trackError(socket: socket)
            case .error(let error):
                await subscriptionManager.trackError(socket: socket)
                handleError(error, from: socket)
            }
        }
    }
}

// MARK: NIP-05 Support
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
        return await subscriptionManager.socket(for: url)
    }
}

// swiftlint:enable file_length
