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
    private var publishFailedEventsTimer: AsyncTimer?
    private var backgroundContext: NSManagedObjectContext
    // TODO: use structured concurrency for this
    private var processingQueue = DispatchQueue(label: "RelayService-processing", qos: .utility)
    private let subscriptionLimit = 10
    private let minimimumOneTimeSubscriptions = 1
    @Dependency(\.analytics) private var analytics
    
    init(persistenceController: PersistenceController) {
        self.persistenceController = persistenceController
        self.backgroundContext = persistenceController.newBackgroundContext()
        self.subscriptions = RelaySubscriptionManager()

        self.saveEventsTimer = AsyncTimer(timeInterval: 1, priority: .high) { [weak self] in
            await self?.backgroundContext.perform(schedule: .immediate) {
                do {
                    try self?.backgroundContext.saveIfNeeded()
                } catch {
                    Log.error("RelayService.saveEventsTimer failed to save with error: \(error.localizedDescription)")
                }
            }
        }
        
        // TODO: fire this after all relays have connected, not right on init
        self.publishFailedEventsTimer = AsyncTimer(timeInterval: 60, onFire: { [weak self] in
            await self?.publishFailedEvents()
        })
        
        Task { @MainActor in
            CurrentUser.shared.viewContext = persistenceController.container.viewContext
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
    
    func removeSubscriptions(for subscriptionIDs: [String]) async {
        for subscriptionID in subscriptionIDs {
            await self.removeSubscription(for: subscriptionID)
        }
    }
    
    func removeSubscription(for subscriptionID: String) async {
        if var subscription = await subscriptions.subscription(from: subscriptionID) {
            if subscription.referenceCount == 1 {
                await subscriptions.removeSubscription(with: subscriptionID)
                await self.sendCloseToAll(for: subscriptionID)
            } else {
                subscription.referenceCount -= 1
                await subscriptions.updateSubscriptions(with: subscription)
            }
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
    
    private func sendCloseToAll(for subscription: String) async {
        await subscriptions.sockets.forEach { self.sendClose(from: $0, subscription: subscription) }
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
    
    /// Takes a RelaySubscription model and makes a websockets request to the given socket
    private func requestEvents(from socket: WebSocketClient, subscription: RelaySubscription) {
        do {
            // Track this so we can close requests if needed
            let request: [Any] = ["REQ", subscription.id, subscription.filter.dictionary]
            let requestData = try JSONSerialization.data(withJSONObject: request)
            let requestString = String(data: requestData, encoding: .utf8)!
            Log.info("\(requestString) sent to \(socket.host)")
            socket.write(string: requestString)
        } catch {
            print("Error: Could not send request \(error.localizedDescription)")
        }
    }
    
    func openSubscription(with filter: Filter, to overrideRelays: [URL]? = nil) async -> RelaySubscription.ID {
        var subscription: RelaySubscription
        
        if let existingSubscription = await subscriptions.subscription(from: filter.id) {
            // dedup
            subscription = existingSubscription
        } else {
            subscription = RelaySubscription(filter: filter)
        }
        subscription.referenceCount += 1
        await subscriptions.updateSubscriptions(with: subscription)
        
        // Fire off REQs in the background
        Task.detached(priority: .utility) {
            await self.processSubscriptionQueue(overrideRelays: overrideRelays)
        }
        
        return subscription.id
    }
    
    func requestMetadata(for authorKey: HexadecimalString?, since: Date?) async -> RelaySubscription.ID? {
        guard let authorKey else {
            return nil
        }
        
        let metaFilter = Filter(
            authorKeys: [authorKey],
            kinds: [.metaData],
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
        await openSockets(overrideRelays: overrideRelays)
        await clearStaleSubscriptions()
        
        // TODO: Make sure active subscriptions are open on all relays
        
        // Strategy: we have two types of subscriptions: long and one time. We can only have a certain number of
        // subscriptions open at once. We want to:
        // - Open as many long running subsriptions as we can, leaving room for `minimumOneTimeSubscriptions`
        // - fill remaining slots with one time filters
        let allSubscriptions = await subscriptions.all
        let waitingLongSubscriptions = allSubscriptions.filter { !$0.isOneTime && !$0.isActive }
        let waitingOneTimeSubscriptions = allSubscriptions.filter { $0.isOneTime && !$0.isActive }
        let openOneTimeSlots = max(subscriptionLimit - waitingLongSubscriptions.count, minimimumOneTimeSubscriptions)
        
        for subscription in waitingLongSubscriptions {
            var subscription = subscription
            subscription.subscriptionStartDate = .now
            await subscriptions.updateSubscriptions(with: subscription)
            await subscriptions.sockets.forEach { requestEvents(from: $0, subscription: subscription) }
        }
        
        for subscription in waitingOneTimeSubscriptions.prefix(openOneTimeSlots) {
            var subscription = subscription
            subscription.subscriptionStartDate = .now
            await subscriptions.updateSubscriptions(with: subscription)
            await subscriptions.sockets.forEach { requestEvents(from: $0, subscription: subscription) }
        }
        
        Log.info("\(await subscriptions.active.count) active subscriptions. " +
            "\(await subscriptions.all.count - subscriptions.active.count) subscriptions waiting in queue.")
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
                await removeSubscription(for: staleSubscription.id)
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
            Log.info("\(subID) has finished responding. Closing.")
            // This is a one-off request. Close it.
            sendClose(from: socket, subscription: subID)
        }
    }
    
    private func parseEvent(_ responseArray: [Any], _ socket: WebSocket) async {
        guard responseArray.count >= 3 else {
            print("Error: invalid EVENT response: \(responseArray)")
            return
        }
        
        guard let eventJSON = responseArray[2] as? [String: Any] else {
            print("Error: invalid EVENT JSON: \(responseArray)")
            return
        }
        
        do {
            let allSubscriptions = await subscriptions.all
            let fulfilledSubscriptions = try await self.backgroundContext.perform {
                let relay = self.relay(from: socket, in: self.backgroundContext)
                let event = try EventProcessor.parse(
                    jsonObject: eventJSON,
                    from: relay,
                    in: self.backgroundContext
                )
                
                relay.unwrap { event.trackDelete(on: $0, context: self.backgroundContext) }
                
                return allSubscriptions.filter { $0.filter.isFulfilled(by: event) }
            }
            
            if !fulfilledSubscriptions.isEmpty {
                Log.info("found \(fulfilledSubscriptions.count) fulfilled filter. Closing.")
                for fulfilledSubscription in fulfilledSubscriptions {
                    await self.sendCloseToAll(for: fulfilledSubscription.id)
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
        await self.openSockets()
        let signedEvent = try await signAndSave(event: event, signingKey: signingKey, in: context)
        for socket in await subscriptions.sockets {
            await publish(from: socket, jsonEvent: signedEvent)
        }
    }
    
    func publish(
        event: JSONEvent,
        to relay: Relay,
        signingKey: KeyPair,
        context: NSManagedObjectContext
    ) async throws {
        await openSockets()
        let signedEvent = try await signAndSave(event: event, signingKey: signingKey, in: context)
        if let socket = await socket(from: relay) {
            await publish(from: socket, jsonEvent: signedEvent)
        } else {
            Log.error("Could not find socket to publish message")
        }
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
        await self.backgroundContext.perform {
            
            let objectContext = self.backgroundContext
            let userSentEvents = Event.unpublishedEvents(context: objectContext)
            
            for event in userSentEvents {
                let shouldBePublishedToRelays: NSMutableSet = (event.shouldBePublishedTo ?? NSSet())
                    .mutableCopy() as! NSMutableSet
                let publishedRelays = (event.publishedTo ?? NSSet()) as Set
                shouldBePublishedToRelays.minus(publishedRelays)
                let missedRelays: [Relay] = Array(Set(_immutableCocoaSet: shouldBePublishedToRelays))
                
                print("\(missedRelays.count) missing a published event.")
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
    
    private func openSockets(overrideRelays: [URL]? = nil) async {
        // Use override relays; fall back to user relays
        
        let relayAddresses: [URL] = await backgroundContext.perform { () -> [URL] in
            if let overrideRelays {
                return overrideRelays
            }
            if let currentUserPubKey = CurrentUser.shared.publicKeyHex,
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
        }
    }
    
    private func handleConnection(from client: WebSocketClient) async {
        if let socket = client as? WebSocket {
            Log.info("websocket is connected: \(String(describing: socket.request.url?.host))")
        } else {
            Log.info("websocket connected with unknown host")
        }
        
        for subscription in await subscriptions.active {
            requestEvents(from: client, subscription: subscription)
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
