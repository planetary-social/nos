//
//  RelayService.swift
//  Nos
//
//  Created by Matthew Lorentz on 2/1/23.
//
// swiftlint:disable file_length
import Foundation
import Starscream
import CoreData
import Logger
import Dependencies

// swiftlint:disable file_length
final class RelayService: ObservableObject {
    private var persistenceController: PersistenceController
    // TODO: use a swift Actor to synchronize access to this
    /// Important: Only access this from the `processingQueue`
    private var requestFilterQueue = [Filter]()
    private var sockets = [WebSocket]()
    private var timer: Timer?
    private var backgroundContext: NSManagedObjectContext
    private var processingQueue = DispatchQueue(label: "RelayService-processing", qos: .userInitiated)
    private let subscriptionLimit = 10
    private let minimimumOneTimeFilters = 1
    @Dependency(\.analytics) private var analytics
    
    init(persistenceController: PersistenceController) {
        self.persistenceController = persistenceController
        self.backgroundContext = persistenceController.newBackgroundContext()

        CurrentUser.shared.context = persistenceController.container.viewContext
        openSockets()
        
        let pubSel = #selector(publishFailedEvents)
        timer = Timer.scheduledTimer(timeInterval: 120, target: self, selector: pubSel, userInfo: nil, repeats: true)
    }
    
    var activeSubscriptions: [String] {
        requestFilterQueue
            .filter { $0.subscriptionStartDate != nil }
            .map { $0.subscriptionId }
    }
        
    private func removeFilter(for subscription: String) {
        // Remove this filter from the queue
        if let foundFilterIndex = requestFilterQueue.firstIndex(where: { $0.subscriptionId == subscription }) {
            requestFilterQueue.remove(at: foundFilterIndex)
        }
    }
        
    private func handleError(_ error: Error?) {
        if let error {
            print("websocket error: \(error)")
        } else {
            print("uknown error")
        }
    }
}

// MARK: Close subscriptions
extension RelayService {
    private func sendClose(from client: WebSocketClient, subscription: String) {
        do {
            let request: [Any] = ["CLOSE", subscription]
            let requestData = try JSONSerialization.data(withJSONObject: request)
            let requestString = String(data: requestData, encoding: .utf8)!
            print(requestString)
            client.write(string: requestString)
        } catch {
            print("Error: Could not send close \(error.localizedDescription)")
        }
    }
    
    func sendCloseToAll(subscriptions: [String]) {
        processingQueue.async {
            
            for subscription in subscriptions {
                self.removeFilter(for: subscription)
                self.sockets.forEach { self.sendClose(from: $0, subscription: subscription) }
            }
            
            self.processFilterQueue()
        }
    }
    
    func sendClose(subscriptions: [String]) {
        processingQueue.async {
            
            for subscription in subscriptions {
                self.removeFilter(for: subscription)
                self.sockets.forEach { self.sendClose(from: $0, subscription: subscription) }
            }
            
            print("\(self.requestFilterQueue.count) filters in use.")
        }
    }
    
    func closeConnection(to relay: Relay) {
        processingQueue.async {
            guard let address = relay.address else { return }
            if let socket = self.socket(for: address) {
                for subId in self.activeSubscriptions {
                    self.sendClose(from: socket, subscription: subId)
                }
                
                self.close(socket: socket)
            }
        }
    }
}

// MARK: Events
extension RelayService {
    private func requestEvents(from client: WebSocketClient, subId: String, filter: Filter = Filter()) {
        do {
            // Track this so we can close requests if needed
            let request: [Any] = ["REQ", filter.subscriptionId, filter.dictionary]
            let requestData = try JSONSerialization.data(withJSONObject: request)
            let requestString = String(data: requestData, encoding: .utf8)!
            Log.info(requestString)
            client.write(string: requestString)
        } catch {
            print("Error: Could not send request \(error.localizedDescription)")
        }
    }
    
    func requestEventsFromAll(filter: Filter = Filter(), relays: [Relay]? = nil) -> String {
        var subscriptionID: String?
  
        processingQueue.sync {

            // TODO: be smarter about redundnat requests particularly now that we are using the since date.
            // Ignore redundant requests
            guard !self.requestFilterQueue.contains(where: { $0.matches(filter) }) else {
                print("Request with identical filter already open. Ignoring. " +
                    "\(self.requestFilterQueue.count) filters in use.")
                let foundFilter = self.requestFilterQueue.first(where: { $0.matches(filter) })
                subscriptionID = foundFilter!.subscriptionId
                return
            }
        }
        
        if let subscriptionID {
            return subscriptionID
        }
        
        // This is not a duplicate request. Register a new UUID to return
        subscriptionID = UUID().uuidString
        filter.subscriptionId = subscriptionID!
        
        // Fire of REQs in the background
        processingQueue.async {
            self.processFilterQueue(adding: filter, relays: relays)
        }
        
        return subscriptionID!
    }
    
    private func processFilterQueue(adding filter: Filter? = nil, relays: [Relay]? = nil) {
        openSockets(for: relays)
        clearStaleSubscriptions()
        
        if let filter {
            requestFilterQueue.append(filter)
        }
        
        var i = 0
        while i < requestFilterQueue.count && activeSubscriptions.count < subscriptionLimit {
            let filter = requestFilterQueue[i]
            i += 1
            if filter.subscriptionStartDate != nil {
                continue
            }
            
            // turn filters into REQs
            if filter.limit != 1 && activeSubscriptions.count == subscriptionLimit - minimimumOneTimeFilters {
                // we need to keep a slot open for one time filters
                continue
            }
            
            filter.subscriptionStartDate = .now
            sockets.forEach { requestEvents(from: $0, subId: filter.subscriptionId, filter: filter) }
        }
        
        Log.info("\(activeSubscriptions.count) active subscriptions. " +
            "\(requestFilterQueue.count - activeSubscriptions.count) subscriptions waiting in queue.")
    }
    
    private func clearStaleSubscriptions() {
        let staleFilters = requestFilterQueue.filter {
            if $0.limit == 1, let filterStartedAt = $0.subscriptionStartDate {
                return filterStartedAt.distance(to: .now) > 5
            }
            return false
        }
        
        if !staleFilters.isEmpty {
            Log.info("Found \(staleFilters.count) stale filters. Closing.")
            
            staleFilters.forEach {
                sendCloseToAll(subscriptions: [$0.subscriptionId])
            }
        }
    }
}

// MARK: Parsing
extension RelayService {
    private func parseEOSE(from socket: WebSocketClient, responseArray: [Any]) {
        guard responseArray.count > 1 else {
            return
        }
        
        if let subId = responseArray[1] as? String {
            if let filter = requestFilterQueue.first(where: { $0.subscriptionId == subId }),
                filter.limit == 1 {
                print("\(subId) has finished responding. Closing.")
                // This is a one-off request. Close it.
                
                // Let's try closing them all. We can't guarantee we got the latest event if not all relays are up
                // to date, but it'll cut down on our number of open filters dramatically.
                // sendClose(from: socket, subscription: subId)
                sendCloseToAll(subscriptions: [subId])
            }
        }
    }
    
    private func parseEvent(_ responseArray: [Any], _ socket: WebSocket) {
        guard responseArray.count >= 3 else {
            print("Error: invalid EVENT response: \(responseArray)")
            return
        }
        
        guard let eventJSON = responseArray[2] as? [String: Any] else {
            print("Error: invalid EVENT JSON: \(responseArray)")
            return
        }
        
        Task.detached(priority: .utility) {
            do {
                try await self.backgroundContext.perform {
                    let event = try EventProcessor.parse(jsonObject: eventJSON, in: self.backgroundContext)
                    
                    // Receiving delete events from other relays
                    if let socketUrl = socket.request.url?.absoluteString {
                        let relay = Relay.findOrCreate(by: socketUrl, context: self.backgroundContext)
                        event.trackDelete(on: relay, context: self.backgroundContext)
                    }

                    let fulfilledFilters = self.requestFilterQueue.filter { $0.isFulfilled(by: event) }
                    if !fulfilledFilters.isEmpty {
                        Log.info("found \(fulfilledFilters.count) fulfilled filter. Closing.")
                        fulfilledFilters.forEach { self.sendCloseToAll(subscriptions: [$0.subscriptionId]) }
                    }
                }
            } catch {
                print("Error: parsing event from relay (\(socket.request.url?.absoluteString ?? "")): " +
                    "\(responseArray)\nerror: \(error.localizedDescription)")
            }
        }
    }

    // swiftlint:disable legacy_objc_type
    private func parseOK(_ responseArray: [Any], _ socket: WebSocket) {
        guard responseArray.count > 2 else {
            return
        }
        
        if let success = responseArray[2] as? Bool,
            let eventId = responseArray[1] as? String,
            let socketUrl = socket.request.url?.absoluteString {
            let objectContext = persistenceController.container.viewContext
            
            if let event = Event.find(by: eventId, context: objectContext) {
                let relay = Relay.findOrCreate(by: socketUrl, context: objectContext)

                if success {
                    print("\(eventId) has sent successfully to \(socketUrl)")
                    event.publishedTo = (event.publishedTo ?? NSSet()).adding(relay)
                    
                    // Receiving a confirmation of my own deletion event
                    event.trackDelete(on: relay, context: objectContext)
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
    // swiftlint:enable legacy_objc_type
    
    private func parseResponse(_ response: String, _ socket: WebSocket) {
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
                #if DEBUG
                Log.info(response)
                #endif
                parseEvent(responseArray, socket)
            case "NOTICE":
                Log.info(response)
                if responseArray[safe: 1] as? String == "rate limited" {
                    analytics.rateLimited(by: socket)
                }
            case "EOSE":
                parseEOSE(from: socket, responseArray: responseArray)
            case "OK":
                parseOK(responseArray, socket)
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
    private func publish(from client: WebSocketClient, event: Event) {
        do {
            // Keep track of this so if it fails we can retry N times
            event.sendAttempts += 1
            let request: [Any] = ["EVENT", event.jsonRepresentation!]
            let requestData = try JSONSerialization.data(withJSONObject: request)
            let requestString = String(data: requestData, encoding: .utf8)!
            print(requestString)
            client.write(string: requestString)
        } catch {
            print("Error: Could not send request \(error.localizedDescription)")
        }
    }
    
    func publishToAll(event: Event) {
        processingQueue.async {
            self.openSockets()
            self.sockets.forEach { self.publish(from: $0, event: event) }
        }
    }
    
    @objc func publishFailedEvents() {
        processingQueue.async {
            
            self.openSockets()
            
            let objectContext = self.persistenceController.container.viewContext
            let userSentEvents = Event.allByUser(context: objectContext)
            let relays = Relay.all(context: objectContext)
            
            // Only attempt to resend a user-created Event to Relays that were available at the time of publication
            // This stops an Event from being sent to Relays that were added after the Event was sent
            for event in userSentEvents {
                let availableRelays = relays.filter { $0.createdAt! < event.createdAt! }
                let publishedRelays: [Relay] = event.publishedTo?.allObjects as? [Relay] ?? []
                let missedRelays: [Relay] = availableRelays.filter { !publishedRelays.contains($0) }
                
                print("\(missedRelays.count) missing a published event.")
                for missedRelay in missedRelays {
                    guard let missedAddress = missedRelay.address else { continue }
                    if let socket = self.socket(for: missedAddress) {
                        // Publish again to this socket
                        print("Republishing \(event.identifier!) on \(missedAddress)")
                        self.publish(from: socket, event: event)
                    }
                }
            }
        }
    }
}

// MARK: Sockets
extension RelayService {
    private func close(socket: WebSocket) {
        socket.disconnect()
        if let index = sockets.firstIndex(where: { $0 === socket }) {
            sockets.remove(at: index)
        }
    }
    
    func closeAllConnections(excluding relays: Set<Relay>?) {
        let relayAddresses = relays?.map { $0.address } ?? []

        let openUnusedSockets = sockets.filter({
            guard let address = $0.request.url?.absoluteString else {
                return true
            }
            return !relayAddresses.contains(address)
        })
        
        if !openUnusedSockets.isEmpty {
            Log.debug("Closing \(openUnusedSockets.count) unused sockets")
        }

        for socket in openUnusedSockets {
            close(socket: socket)
        }
    }
    
    private func openSockets(for overrideRelays: [Relay]? = nil) {
        // Use override relays; fall back to user relays
        let activeRelays = overrideRelays ?? CurrentUser.shared.author?.relays?.allObjects
        
        guard let relays = activeRelays as? [Relay] else {
            print("No relays provided or associated with author!")
            return
        }

        for relay in relays {
            guard let relayAddress = relay.address?.lowercased(),
                let relayURL = URL(string: relayAddress) else {
                continue
            }
                        
            guard !sockets.contains(where: { $0.request.url == relayURL }) else {
                continue
            }
            
            var request = URLRequest(url: relayURL)
            request.timeoutInterval = 10
            let socket = WebSocket(request: request, compressionHandler: .none)
            socket.callbackQueue = processingQueue
            socket.delegate = self
            sockets.append(socket)
            socket.connect()
        }
    }
    
    private func socket(for address: String) -> WebSocket? {
        if let index = sockets.firstIndex(where: { $0.request.url!.absoluteString == address }) {
            return sockets[index]
        }
        return nil
    }
}

// MARK: WebSocketDelegate
extension RelayService: WebSocketDelegate {
    func didReceive(event: WebSocketEvent, client: WebSocketClient) {
        guard let socket = client as? WebSocket else {
            return
        }
        
        switch event {
        case .connected(let headers):
            print("websocket is connected: \(headers)")
            requestFilterQueue
                .filter { $0.subscriptionStartDate != nil }
                .forEach { self.requestEvents(from: client, subId: $0.subscriptionId, filter: $0) }
        case .disconnected(let reason, let code):
            if let index = sockets.firstIndex(where: { $0 === socket }) {
                sockets.remove(at: index)
            }
            print("websocket is disconnected: \(reason) with code: \(code)")
        case .text(let string):
            parseResponse(string, socket)
        case .binary:
            break
        case .ping, .pong, .viabilityChanged, .reconnectSuggested:
            break
        case .cancelled:
            if let index = sockets.firstIndex(where: { $0 === socket }) {
                sockets.remove(at: index)
            }
            print("websocket is cancelled")
        case .error(let error):
            if let index = sockets.firstIndex(where: { $0 === socket }) {
                sockets.remove(at: index)
            }
            handleError(error)
        }
    }
}

// MARK: NIP-05 Support
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
}
// swiftlint:enable file_length
