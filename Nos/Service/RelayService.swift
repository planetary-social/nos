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

final class RelayService: ObservableObject {
    private var persistenceController: PersistenceController
    // TODO: use a swift Actor to synchronize access to this
    /// Important: Only access this from the `processingQueue`
    private var requestFilterSet = Set<Filter>()
    private var sockets = [WebSocket]()
    private var timer: Timer?
    private var backgroundContext: NSManagedObjectContext
    private var processingQueue = DispatchQueue(label: "RelayService-processing", qos: .userInitiated)
    
    init(persistenceController: PersistenceController) {
        self.persistenceController = persistenceController
        self.backgroundContext = persistenceController.newBackgroundContext()

        CurrentUser.shared.context = persistenceController.container.viewContext
        openSockets()
        
        let pubSel = #selector(publishFailedEvents)
        timer = Timer.scheduledTimer(timeInterval: 120, target: self, selector: pubSel, userInfo: nil, repeats: true)
    }
    
    var activeSubscriptions: [String] {
        requestFilterSet.map { $0.subscriptionId }
    }
        
    private func removeFilter(for subscription: String) {
        // Remove this filter from the queue
        if let foundFilter = requestFilterSet.first(where: { $0.subscriptionId == subscription }) {
            requestFilterSet.remove(foundFilter)
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
            
            print("\(self.requestFilterSet.count) filters in use.")
        }
    }
    
    func sendClose(to relays: [Relay], subscriptions: [String]) {
        processingQueue.async {
            
            for subscription in subscriptions {
                self.removeFilter(for: subscription)
                self.sockets.forEach { self.sendClose(from: $0, subscription: subscription) }
            }
            
            print("\(self.requestFilterSet.count) filters in use.")
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
            // Keep this open
            openSockets(for: relays)

            // Ignore redundant requests
            guard !requestFilterSet.contains(filter) else {
                print("Request with identical filter already open. Ignoring. \(requestFilterSet.count) filters in use.")
                let foundFilter = requestFilterSet.first(where: { $0 == filter })
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
            filter.subscriptionStartDate = .now
            self.requestFilterSet.insert(filter)
            print("\(self.requestFilterSet.count) filters in use.")
            
            self.sockets.forEach { self.requestEvents(from: $0, subId: subscriptionID!, filter: filter) }
            
            self.clearStaleSubscriptions()
        }
        
        return subscriptionID!
    }
    
    private func clearStaleSubscriptions() {
        let staleFilters = requestFilterSet.filter {
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
            if let filter = requestFilterSet.first(where: { $0.subscriptionId == subId }),
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
        
        Task.detached(priority: .userInitiated) {
            do {
                try await self.backgroundContext.perform {
                    let event = try EventProcessor.parse(jsonObject: eventJSON, in: self.backgroundContext)
                    // TODO: synchronize access to requestFilterSet
                    let fulfilledFilters = self.requestFilterSet.filter { $0.isFulfilled(by: event) }
                    if !fulfilledFilters.isEmpty {
                        Log.info("found \(fulfilledFilters.count) fulfilled filter. Closing.")
                        fulfilledFilters.forEach { self.sendCloseToAll(subscriptions: [$0.subscriptionId]) }
                    }
                }
            } catch {
                print("Error: parsing event from relay (\(socket.request.url?.absoluteString ?? "")): \(responseArray)")
            }
        }
    }
    
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
                    if let pubRelays = event.publishedTo?.mutableCopy() as? NSMutableSet {
                        pubRelays.add(relay)
                        event.publishedTo = pubRelays
                        print("Tracked publish to relay: \(socketUrl)")
                    }
                } else {
                    // This will be picked up later in publishFailedEvents
                    if responseArray.count > 2, let message = responseArray[3] as? String {
                        // Mark duplicates or replaces as done on our end
                        if message.contains("replaced:") || message.contains("duplicate:") {
                            if let pubRelays = event.publishedTo?.mutableCopy() as? NSMutableSet {
                                pubRelays.add(relay)
                                event.publishedTo = pubRelays
                                print("Tracked publish to relay: \(socketUrl)")
                            }
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
                Log.info(response)
                parseEvent(responseArray, socket)
            case "NOTICE":
                print(response)
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
            requestFilterSet.forEach { self.requestEvents(from: client, subId: $0.subscriptionId, filter: $0) }
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
