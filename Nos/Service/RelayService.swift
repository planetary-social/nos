//
//  RelayService.swift
//  Nos
//
//  Created by Matthew Lorentz on 2/1/23.
//

import Foundation
import Starscream
import CoreData

final class RelayService: ObservableObject {
    private var persistenceController: PersistenceController
    private var requestFilterSet = Set<Filter>()
    private var sockets = [WebSocket]()
    private var timer: Timer?
    private var backgroundContext: NSManagedObjectContext
    
    init(persistenceController: PersistenceController) {
        self.persistenceController = persistenceController
        self.backgroundContext = persistenceController.newBackgroundContext()
        openSocketsForRelays()
        
        let pubSel = #selector(publishFailedEvents)
        timer = Timer.scheduledTimer(timeInterval: 120, target: self, selector: pubSel, userInfo: nil, repeats: true)
    }
    
    var activeSubscriptions: [String] {
        requestFilterSet.map { $0.subscriptionId }
    }
        
    func removeFilter(for subscription: String) {
        // Remove this filter from the queue
        if let foundFilter = requestFilterSet.first(where: { $0.subscriptionId == subscription }) {
            requestFilterSet.remove(foundFilter)
        }
    }
        
    func handleError(_ error: Error?) {
        if let error {
            print(error)
        } else {
            print("uknown error")
        }
    }
}

// MARK: Close subscriptions
extension RelayService {
    func sendClose(from client: WebSocketClient, subscription: String) {
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
        openSocketsForRelays()
        
        for subscription in subscriptions {
            removeFilter(for: subscription)
            sockets.forEach { sendClose(from: $0, subscription: subscription) }
        }
    }
}

// MARK: Events
extension RelayService {
    func requestEvents(from client: WebSocketClient, subId: String, filter: Filter = Filter()) {
        do {
            // Track this so we can close requests if needed
            filter.subscriptionId = subId
            let request: [Any] = ["REQ", filter.subscriptionId, filter.dictionary]
            let requestData = try JSONSerialization.data(withJSONObject: request)
            let requestString = String(data: requestData, encoding: .utf8)!
            print(requestString)
            client.write(string: requestString)
        } catch {
            print("Error: Could not send request \(error.localizedDescription)")
        }
    }
    
    func requestEventsFromAll(filter: Filter = Filter()) -> String {
        // Keep this open
        openSocketsForRelays()

        // Ignore redundant requests
        guard !requestFilterSet.contains(filter) else {
            print("Request with identical filter already open. Ignoring. \(requestFilterSet.count) filters in use.")
            let foundFilter = requestFilterSet.first(where: { $0 == filter })
            return foundFilter!.subscriptionId
        }

        requestFilterSet.insert(filter)
        print("\(requestFilterSet.count) filters in use.")

        let subId = UUID().uuidString
        sockets.forEach { requestEvents(from: $0, subId: subId, filter: filter) }
        
        return subId
    }
}

// MARK: Parsing
extension RelayService {
    func parseEOSE(_ responseArray: [Any]) {
        guard responseArray.count > 1 else {
            return
        }
        
        if let subId = responseArray[1] as? String {
            print("\(subId) has finished responding")
        }
    }
    
    func parseEvent(_ responseArray: [Any]) {
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
                    _ = try EventProcessor.parse(jsonObject: eventJSON, in: self.backgroundContext)
                }
            } catch {
                print("Error: parsing event from relay: \(responseArray)")
            }
        }
    }
    
    func parseOK(_ responseArray: [Any], _ socket: WebSocket) {
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
    
    func parseResponse(_ response: String, _ socket: WebSocket) {
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
                parseEvent(responseArray)
            case "NOTICE":
                print(response)
            case "EOSE":
                parseEOSE(responseArray)
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
    func publish(from client: WebSocketClient, event: Event) {
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
        openSocketsForRelays()
        sockets.forEach { publish(from: $0, event: event) }
    }
    
    @objc func publishFailedEvents() {
        openSocketsForRelays()

        let objectContext = persistenceController.container.viewContext
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
                if let socket = socket(for: missedAddress) {
                    // Publish again to this socket
                    print("Republishing \(event.identifier!) on \(missedAddress)")
                    publish(from: socket, event: event)
                }
            }
        }
    }
}

// MARK: Sockets
extension RelayService {
    func close(socket: WebSocket) {
        socket.disconnect()
        if let index = sockets.firstIndex(where: { $0 === socket }) {
            sockets.remove(at: index)
        }
    }
    
    func openSocketsForRelays() {
        guard let relays = CurrentUser.author?.relays?.allObjects as? [Relay] else {
            print("No relays associated with author!")
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
            socket.delegate = self
            sockets.append(socket)
            socket.connect()
        }
    }
    
    func socket(for address: String) -> WebSocket? {
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
        case .disconnected(let reason, let code):
            if let index = sockets.firstIndex(where: { $0 === socket }) {
                sockets.remove(at: index)
            }
            print("websocket is disconnected: \(reason) with code: \(code)")
        case .text(let string):
            parseResponse(string, socket)
            print("Received text (\(socket.request.url?.absoluteString ?? "unknown")): \(string)")
        case .binary(let data):
            print("Received data: \(data.count)")
        case .ping, .pong, .viabilityChanged, .reconnectSuggested:
            break
        case .cancelled:
            if let index = sockets.firstIndex(where: { $0 === socket }) {
                sockets.remove(at: index)
            }
        case .error(let error):
            if let index = sockets.firstIndex(where: { $0 === socket }) {
                sockets.remove(at: index)
            }
            handleError(error)
        }
    }
}
