//
//  RelayService.swift
//  Nos
//
//  Created by Matthew Lorentz on 2/1/23.
//
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
    
    private var persistenceController: PersistenceController
    private var subscriptions: RelaySubscriptionManager
    private var saveEventsTimer: AsyncTimer?
    private var backgroundProcessTimer: AsyncTimer?
    private var backgroundContext: NSManagedObjectContext
    private var parseContext: NSManagedObjectContext
    // TODO: use structured concurrency for this
    private var processingQueue = DispatchQueue(label: "RelayService-processing", qos: .utility)
    @Dependency(\.analytics) private var analytics
    @MainActor @Dependency(\.currentUser) private var currentUser
    
    init(persistenceController: PersistenceController) {
        self.persistenceController = persistenceController
        self.backgroundContext = persistenceController.newBackgroundContext()
        self.parseContext = persistenceController.newBackgroundContext()
        self.subscriptions = RelaySubscriptionManager()

        self.saveEventsTimer = AsyncTimer(timeInterval: 1, priority: .high) { [weak self] in
            do {
                try await self?.parseContext.perform(schedule: .immediate) {
                    try self?.parseContext.saveIfNeeded()
                }                
                try await self?.backgroundContext.perform(schedule: .immediate) {
                    try self?.backgroundContext.saveIfNeeded()
                }                
            } catch {
                Log.error("RelayService.saveEventsTimer failed to save with error: \(error.localizedDescription)")
            }
            
            await self?.processSubscriptionQueue()
        }
        
        // TODO: fire this after all relays have connected, not right on init
        self.backgroundProcessTimer = AsyncTimer(timeInterval: 60, onFire: { [weak self] in
            await self?.publishFailedEvents()
            await self?.deleteExpiredEvents()
        })
        
        Task { @MainActor in
            currentUser.viewContext = persistenceController.container.viewContext
            _ = await openSockets()
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    deinit {
        saveEventsTimer?.cancel()
    }
    
    @objc func appWillEnterForeground() {
        Task { await openSockets() }
    }
    
    private func handleError(_ error: Error?, from socket: WebSocketClient) {
        if let error {
            Log.info("websocket error: \(error) from: \(socket.host)")
        } else {
            Log.info("unknown websocket error from: \(socket.host)")
        }
    }
}

// MARK: Close subscriptions
extension RelayService {
    
    func decrementSubscriptionCount(for subscriptionIDs: [String]) async {
        for subscriptionID in subscriptionIDs {
            await self.decrementSubscriptionCount(for: subscriptionID)
        }
    }
    
    func decrementSubscriptionCount(for subscriptionID: String) async {
        let subscriptionStillActive = await subscriptions.decrementSubscriptionCount(for: subscriptionID)
        if !subscriptionStillActive {
            await self.sendCloseToAll(for: subscriptionID)
        }
    }

    private func sendClose(from client: WebSocketClient, subscription: String) {
        do {
            let request: [Any] = ["CLOSE", subscription]
            let requestData = try JSONSerialization.data(withJSONObject: request)
            let requestString = String(data: requestData, encoding: .utf8)!
            Log.info("\(requestString) sent to \(client.host)")
            client.write(string: requestString)
        } catch {
            print("Error: Could not send close \(error.localizedDescription)")
        }
    }
    
    private func sendCloseToAll(for subscription: RelaySubscription.ID) async {
        await subscriptions.sockets.forEach { self.sendClose(from: $0, subscription: subscription) }
        Task { await processSubscriptionQueue(overrideRelays: nil) }
    }
    
    func closeConnection(to relay: Relay) async {
        guard let address = relay.address else { return }
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
    
    func openSubscription(with filter: Filter, to overrideRelays: [URL]? = nil) async -> RelaySubscription.ID {
        let subscriptionID = await subscriptions.queueSubscription(with: filter, to: overrideRelays)
        
        // Fire off REQs in the background
        Task { await self.processSubscriptionQueue(overrideRelays: overrideRelays) }
        
        return subscriptionID
    }
    
    func requestMetadata(for authorKey: HexadecimalString?, since: Date?) async -> RelaySubscription.ID? {
        guard let authorKey else {
            return nil
        }
        
        let metaFilter = Filter(
            authorKeys: [authorKey],
            kinds: [.metaData],
            limit: 1, 
            since: since
        )
        return await openSubscription(with: metaFilter)
    }
    
    /// Requests a single event from all relays
    func requestEvent(with eventID: String?) async -> RelaySubscription.ID? {
        guard let eventID = eventID else {
            return nil
        }
        
        return await openSubscription(with: Filter(eventIDs: [eventID], limit: 1))
    }
    
    private func processSubscriptionQueue(overrideRelays: [URL]? = nil) async {
        let relays = await openSockets(overrideRelays: overrideRelays)
        await clearStaleSubscriptions()
        
        await subscriptions.processSubscriptionQueue(relays: relays)
    }
    
    private func clearStaleSubscriptions() async {
        var staleSubscriptions = [RelaySubscription]()
        staleSubscriptions = await subscriptions.active.filter {
            if $0.isOneTime, let filterStartedAt = $0.subscriptionStartDate {
                return filterStartedAt.distance(to: .now) > 5
            }
            return false
        }
        
        if !staleSubscriptions.isEmpty {
            Log.info("Found \(staleSubscriptions.count) stale subscriptions. Closing.")
            
            for staleSubscription in staleSubscriptions {
                await subscriptions.forceCloseSubscriptionCount(for: staleSubscription.id)
                await sendCloseToAll(for: staleSubscription.id)
            }
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
            Log.info("\(socket.host) has finished responding on \(subID). Closing subscription.")
            // This is a one-off request. Close it.
            sendClose(from: socket, subscription: subID)
        }
    }
    
    private func parseEvent(_ responseArray: [Any], _ socket: WebSocket) async {
        guard responseArray.count >= 3 else {
            print("Error: invalid EVENT response: \(responseArray)")
            return
        }
        
        guard let eventJSON = responseArray[safe: 2] as? [String: Any] else {
            print("Error: invalid EVENT JSON: \(responseArray)")
            return
        }
        
        if await !shouldParseEvent(responseArray: responseArray, json: eventJSON) {
            return
        }
        
        do {
            let allSubscriptions = await subscriptions.all
            let fulfilledSubscriptions = try await self.parseContext.perform {
                let relay = self.relay(from: socket, in: self.parseContext)
                let event = try EventProcessor.parse(
                    jsonObject: eventJSON,
                    from: relay,
                    in: self.parseContext
                )
                
                relay.unwrap { event.trackDelete(on: $0, context: self.parseContext) }
                
                return allSubscriptions.filter { $0.filter.isFulfilled(by: event) }
            }
            
            if !fulfilledSubscriptions.isEmpty {
                Log.info("found \(fulfilledSubscriptions.count) fulfilled filter. Closing.")
                for fulfilledSubscription in fulfilledSubscriptions {
                    await subscriptions.forceCloseSubscriptionCount(for: fulfilledSubscription.id)
                    await sendCloseToAll(for: fulfilledSubscription.id)
                }
            }
        } catch {
            print("Error: parsing event from relay (\(socket.request.url?.absoluteString ?? "")): " +
                "\(responseArray)\nerror: \(error.localizedDescription)")
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
                        event.publishedTo = (event.publishedTo ?? NSSet()).adding(relay)
                        
                        // Receiving a confirmation of my own deletion event
                        event.trackDelete(on: relay, context: self.backgroundContext)
                    } else {
                        // This will be picked up later in publishFailedEvents
                        if responseArray.count > 2, let message = responseArray[3] as? String {
                            // Mark duplicates or replaces as done on our end
                            if message.contains("replaced:") || message.contains("duplicate:") {
                                event.publishedTo = (event.publishedTo ?? NSSet()).adding(relay)
                            } else {
                                print("\(eventId) has been rejected. Given reason: \(message)")
                            }
                        } else {
                            print("\(eventId) has been rejected. No given reason.")
                        }
                    }
                } else {
                    print("Error: got OK for missing Event: \(eventId)")
                }
            }
        }
    }
    
    private func parseResponse(_ response: String, _ socket: WebSocket) async {
        #if DEBUG
        Log.info("from \(socket.host): \(response)")
        #endif
        
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
                await parseEvent(responseArray, socket)
            case "NOTICE":
                if responseArray[safe: 1] as? String == "rate limited" {
                    analytics.rateLimited(by: socket)
                }
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
     
    func shouldParseEvent(responseArray: [Any], json eventJSON: [String: Any]) async -> Bool {
        // Drop out of network subscriptions if the filter has inNetwork == true
        if let subscriptionID = responseArray[safe: 1] as? RelaySubscription.ID,
            let authorKey = eventJSON[JSONEvent.CodingKeys.pubKey.rawValue] as? HexadecimalString,
            let subscription = await subscriptions.subscription(from: subscriptionID) {
            if subscription.filter.inNetwork {
                let eventInNetwork = await currentUser.socialGraph.contains(authorKey) 
                if !eventInNetwork {
                    let eventID = eventJSON[JSONEvent.CodingKeys.id.rawValue] ?? "nil"
                    Log.info("Dropping out of network event \(eventID).")
                    return false
                }
            }
        }
        
        return true
    }
}

// MARK: Publish
extension RelayService {
    
    private func publish(from client: WebSocketClient, jsonEvent: JSONEvent) async {
        do {
            // Keep track of this so if it fails we can retry N times
            let request: [Any] = ["EVENT", jsonEvent.dictionary]
            let requestData = try JSONSerialization.data(withJSONObject: request)
            let requestString = String(data: requestData, encoding: .utf8)!
            print(requestString)
            client.write(string: requestString)
        } catch {
            print("Error: Could not send request \(error.localizedDescription)")
        }
    }
    
    func publishToAll(event: JSONEvent, signingKey: KeyPair, context: NSManagedObjectContext) async throws {
        _ = await self.openSockets()
        let signedEvent = try await signAndSave(event: event, signingKey: signingKey, in: context)
        for socket in await subscriptions.sockets {
            await publish(from: socket, jsonEvent: signedEvent)
        }
    }

    func publish(
        event: JSONEvent,
        to relays: [Relay],
        signingKey: KeyPair,
        context: NSManagedObjectContext
    ) async throws {
        await openSockets()
        let signedEvent = try await signAndSave(event: event, signingKey: signingKey, in: context)
        for relay in relays {
            if let socket = await socket(from: relay) {
                await publish(from: socket, jsonEvent: signedEvent)
            } else {
                Log.error("Could not find socket to publish message")
            }
        }
    }
    
    func publish(
        event: JSONEvent,
        to relay: Relay,
        signingKey: KeyPair,
        context: NSManagedObjectContext
    ) async throws {
        try await publish(event: event, to: [relay], signingKey: signingKey, context: context)
    }
    
    private func signAndSave(
        event: JSONEvent,
        signingKey: KeyPair,
        in context: NSManagedObjectContext
    ) async throws -> JSONEvent {
        var jsonEvent = event
        try jsonEvent.sign(withKey: signingKey)
        
        try await context.perform {
            let event = try EventProcessor.parse(jsonEvent: jsonEvent, from: nil, in: context)
            let relays = try context.fetch(Relay.relays(for: event.author!))
            event.shouldBePublishedTo = NSSet(array: relays)
            try context.save()
        }
        
        return jsonEvent
    }
    
    func publishFailedEvents() async {
        guard let user = await currentUser.author else {
            return
        }
        
        await self.backgroundContext.perform {
            
            let objectContext = self.backgroundContext
            let userSentEvents = Event.unpublishedEvents(for: user, context: objectContext)
            
            for event in userSentEvents {
                let shouldBePublishedToRelays: NSMutableSet = (event.shouldBePublishedTo ?? NSSet())
                    .mutableCopy() as! NSMutableSet
                let publishedRelays = (event.publishedTo ?? NSSet()) as Set
                shouldBePublishedToRelays.minus(publishedRelays)
                let missedRelays: [Relay] = Array(Set(_immutableCocoaSet: shouldBePublishedToRelays))
                
                print("\(missedRelays.count) relays missing a published event.")
                for missedRelay in missedRelays {
                    guard let missedAddress = missedRelay.address else { continue }
                    Task {
                        if let socket = await self.subscriptions.socket(for: missedAddress),
                            let jsonEvent = event.codable {
                            // Publish again to this socket
                            print("Republishing \(event.identifier!) on \(missedAddress)")
                            await self.publish(from: socket, jsonEvent: jsonEvent)
                        }
                    }
                }
            }
        }
    }
    
    func deleteExpiredEvents() async {
        await self.backgroundContext.perform {
            do {
                for event in try self.backgroundContext.fetch(Event.expiredRequest()) {
                    self.backgroundContext.delete(event)
                }
            } catch {
                Log.error("Error fetching expired events \(error.localizedDescription)")
            }
        }
    }
}

// MARK: Sockets
extension RelayService {
    
    @MainActor func closeAllConnections(excluding relays: Set<Relay>?) async {
        let relayAddresses = relays?.map { $0.address } ?? []

        let openUnusedSockets = await subscriptions.sockets.filter({
            guard let address = $0.request.url?.absoluteString else {
                return true
            }
            return !relayAddresses.contains(address)
        })
        
        if !openUnusedSockets.isEmpty {
            Log.debug("Closing \(openUnusedSockets.count) unused sockets")
        }

        for socket in openUnusedSockets {
            await subscriptions.close(socket: socket)
        }
    }
    
    @MainActor private func openSockets(overrideRelays: [URL]? = nil) async -> [URL] {
        // Use override relays; fall back to user relays
        
        let relayAddresses: [URL] = await backgroundContext.perform { () -> [URL] in
            if let overrideRelays {
                return overrideRelays
            }
            if let currentUserPubKey = self.currentUser.publicKeyHex,
                let currentUser = try? Author.find(by: currentUserPubKey, context: self.backgroundContext),
                let userRelays = currentUser.relays?.allObjects as? [Relay] {
                return userRelays.compactMap { $0.addressURL }
            } else {
                return []
            }
        }
        
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
                    print(error)
                }
            }
        }

        return relayAddresses
    }

    private func queryRelayMetadataIfNeeded(_ relayAddress: URL) async throws {
        let address = relayAddress.absoluteString
        let shouldQueryRelayMetadata = try await backgroundContext.perform { [backgroundContext] in
            guard let relay = try backgroundContext.fetch(Relay.relay(by: address)).first else {
                return false
            }
            guard let timestamp = relay.metadata?.timestamp else {
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
            let relayMetadata = try RelayMetadata(
                context: backgroundContext,
                jsonRelayMetadata: metadata
            )
            relay.metadata = relayMetadata
            try backgroundContext.saveIfNeeded()
        }
    }
    
    private func handleConnection(from client: WebSocketClient) async {
        if let socket = client as? WebSocket {
            Log.info("websocket is connected: \(String(describing: socket.request.url?.host))")
        } else {
            Log.info("websocket connected with unknown host")
        }
        
        for subscription in await subscriptions.active {
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
            case .ping, .pong, .viabilityChanged, .reconnectSuggested:
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
    
    func verifyInternetIdentifier(identifier: String, userPublicKey: String) async -> Bool {
        let internetIdentifierPublicKey = await retrieveInternetIdentifierPublicKeyHex(identifier)
        return internetIdentifierPublicKey == userPublicKey
    }
    
    func retrieveInternetIdentifierPublicKeyHex(_ identifier: String) async -> String? {
        let localPart = identifier.components(separatedBy: "@")[safe: 0] ?? ""
        let domain = domain(from: identifier)
        let urlString = "https://\(domain)/.well-known/nostr.json?name=\(localPart)"
        guard let url = URL(string: urlString) else {
            Log.info("Invalid URL: \(urlString)")
            return nil
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            if let names = json?["names"] as? [String: String], let pubkey = names[localPart] {
                return pubkey
            }
        } catch {
            Log.info("Error verifying username: \(error.localizedDescription)")
        }
        return nil
    }

    func identifierToShow(_ identifier: String) -> String {
        let localPart = identifier.components(separatedBy: "@")[safe: 0]
        let domain = identifier.components(separatedBy: "@")[safe: 1]
        if localPart == "_" {
            // The identifier _@domain is the "root" identifier, and is displayed as: <domain>
            return domain ?? ""
        }
        return identifier
    }
    
    func domain(from identifier: String) -> String {
        identifier.components(separatedBy: "@")[safe: 1] ?? ""
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
    
    func socket(from relay: Relay) async -> WebSocket? {
        await subscriptions.sockets.first(where: { $0.request.url?.absoluteString == relay.addressURL?.absoluteString })
    }

    func unsURL(from unsIdentifier: String) -> URL? {
        let urlString = "https://explorer.universalname.space/uns/\(unsIdentifier)"
        guard let url = URL(string: urlString) else { return nil }
        return url
    }
}
// swiftlint:enable file_length
