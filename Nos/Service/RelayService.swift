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
    private var requestFilterSet = Set<Filter>()
    
    private var sockets = [WebSocket]()
    
    private var persistenceController: PersistenceController
    
    init(persistenceController: PersistenceController) {
        self.persistenceController = persistenceController
        openSocketsForRelays()
    }
    
    var allRelayAddresses: [String] {
        let objectContext = persistenceController.container.viewContext
        let relays = try? objectContext.fetch(Relay.allRelaysRequest())
        let addresses = relays?.map { $0.address!.lowercased() } ?? []

        return addresses
    }
    
    func removeFilter(for subscription: String) {
        // Remove this filter from the queue
        if let foundFilter = requestFilterSet.first(where: { $0.subscriptionId == subscription }) {
            requestFilterSet.remove(foundFilter)
        }
    }
    
    func openSocketsForRelays() {
        let objectContext = persistenceController.container.viewContext
        do {
            let relays = try objectContext.fetch(Relay.allRelaysRequest())
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
        } catch {
            print(error)
            // TODO:
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
            print("📡Request already open. Ignoring. \(requestFilterSet.count) outstanding requests")
            let foundFilter = requestFilterSet.first(where: { $0 == filter })
            return foundFilter!.subscriptionId
        }

        requestFilterSet.insert(filter)
        print("📡\(requestFilterSet.count) outstanding requests")
        for request in requestFilterSet {
            print("📡: \(request.dictionary)")
        }

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
            print("got invalid EVENT response: \(responseArray)")
            return
        }
        
        guard let eventJSON = responseArray[2] as? [String: Any] else {
            print("got invalid EVENT JSON: \(responseArray)")
            return
        }
        
        do {
            _ = try EventProcessor.parse(jsonObject: eventJSON, in: persistenceController.container.viewContext)
        } catch {
            print("error parsing event from relay: \(responseArray)")
        }
    }
    
    func parseOK(_ responseArray: [Any]) {
        guard responseArray.count > 2 else {
            return
        }
        
        if let result = responseArray[2] as? Bool, let subId = responseArray[1] as? String {
            let resultString = result ? "sent succesfully" : "failed"
            print("\(subId) has \(resultString)")
        }
    }
    
    func parseResponse(_ response: String) {
        do {
            guard let responseData = response.data(using: .utf8) else {
                throw EventError.utf8Encoding
            }
            let jsonResponse = try JSONSerialization.jsonObject(with: responseData)
            guard let responseArray = jsonResponse as? [Any],
                let responseType = responseArray.first as? String else {
                print("got unparseable response: \(response)")
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
                parseOK(responseArray)
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
}

// MARK: WebSocketDelegate
extension RelayService: WebSocketDelegate {
    func didReceive(event: WebSocketEvent, client: WebSocketClient) {
        switch event {
        case .connected(let headers):
            print("websocket is connected: \(headers)")
        case .disconnected(let reason, let code):
            if let socket = client as? WebSocket, let index = sockets.firstIndex(where: { $0 === socket }) {
                sockets.remove(at: index)
            }
            print("websocket is disconnected: \(reason) with code: \(code)")
        case .text(let string):
            parseResponse(string)
            print("Received text: \(string)")
        case .binary(let data):
            print("Received data: \(data.count)")
        case .ping, .pong, .viabilityChanged, .reconnectSuggested:
            break
        case .cancelled:
            if let socket = client as? WebSocket, let index = sockets.firstIndex(where: { $0 === socket }) {
                sockets.remove(at: index)
            }
        case .error(let error):
            if let socket = client as? WebSocket, let index = sockets.firstIndex(where: { $0 === socket }) {
                sockets.remove(at: index)
            }
            handleError(error)
        }
    }
}


