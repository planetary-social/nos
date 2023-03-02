//
//  RelayService.swift
//  Nos
//
//  Created by Matthew Lorentz on 2/1/23.
//

import Foundation
import Starscream
import CoreData

final class RelayService: WebSocketDelegate, ObservableObject {
    private var requestQueue = Set<Filter>()
    
    private var sockets = [WebSocket]()
    
    private var persistenceController: PersistenceController
    
    init(persistenceController: PersistenceController) {
        self.persistenceController = persistenceController
        openSocketsForRelays()
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
    
    var allRelayAddresses: [String] {
        let objectContext = persistenceController.container.viewContext
        let relays = try? objectContext.fetch(Relay.allRelaysRequest())
        let addresses = relays?.map { $0.address!.lowercased() } ?? []

        return addresses
    }
    
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
    
	func requestEvents(from client: WebSocketClient, filter: Filter = Filter()) {
        do {
            // Track this so we can close requests if needed
            filter.uuid = UUID().uuidString
            let request: [Any] = ["REQ", filter.uuid, filter.dictionary]
            let requestData = try JSONSerialization.data(withJSONObject: request)
            let requestString = String(data: requestData, encoding: .utf8)!
            print(requestString)
            client.write(string: requestString)
        } catch {
            print("Error: Could not send request \(error.localizedDescription)")
        }
    }
    
    func requestEventsFromAll(filter: Filter = Filter()) {
        // Keep this open
        openSocketsForRelays()

        // Ignore redundant requests
        guard !requestQueue.contains(filter) else {
            print("📡Request already open. Ignoring. \(requestQueue.count) outstanding requests")
            return
        }
        
        // TODO: This only works because all requests are of kinds [.text, .metaData, .contactList] together
        if requestQueue.count > 1 {
            print("📡Merging \(requestQueue.count) metaData filters")
            // Close all requests of this kind
            var authorPubKeys: [String] = []
            for filter in requestQueue {
                let keys = filter.dictionary["authors"] as! [String]
                for key in keys where !authorPubKeys.contains(key) {
                    authorPubKeys.append(key)
                }
                sockets.forEach { sendClose(from: $0, subscription: filter.uuid) }
                requestQueue.remove(filter)
            }
            
            // Now modify this filter to have all authors
            filter.authorKeys = authorPubKeys
        }
        
        requestQueue.insert(filter)
        print("📡\(requestQueue.count) outstanding requests")
        sockets.forEach { requestEvents(from: $0, filter: filter) }

        for request in requestQueue {
            print("📡: \(request.dictionary)")
        }
    }
    
    func sendEvent(from client: WebSocketClient, event: Event) {
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
    
    func sendClose(from client: WebSocketClient, subscription: String) {
        do {
            let request: [Any] = ["CLOSE", subscription]
            let requestData = try JSONSerialization.data(withJSONObject: request)
            let requestString = String(data: requestData, encoding: .utf8)!
            client.write(string: requestString)
        } catch {
            print("Error: Could not send close \(error.localizedDescription)")
        }
    }

    func sendEventToAll(event: Event) {
        openSocketsForRelays()
        sockets.forEach { sendEvent(from: $0, event: event) }
    }
    
    func sendCloseToAll(subscription: String) {
        openSocketsForRelays()
        sockets.forEach { sendClose(from: $0, subscription: subscription) }
    }
    
    func publish(_ event: Event) throws {
        guard let eventJSON = event.jsonRepresentation else {
            throw EventError.jsonEncoding
        }
        
        let eventMessageJSON: [Any] = ["EVENT", eventJSON]
        let eventMessageData = try JSONSerialization.data(
            withJSONObject: eventMessageJSON,
            options: .withoutEscapingSlashes
        )
        guard let eventMessageString = String(data: eventMessageData, encoding: .utf8) else {
            throw EventError.utf8Encoding
        }
        sockets.forEach { $0.write(string: eventMessageString) }
    }
    
    func handleError(_ error: Error?) {
        if let error {
            print(error)
        } else {
            print("uknown error")
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
                guard responseArray.count >= 3 else {
                    print("got invalid EVENT response: \(response)")
                    return
                }
                
                guard let eventJSON = responseArray[2] as? [String: Any] else {
                    print("got invalid EVENT JSON: \(response)")
                    return
                }
                
                do {
                    _ = try EventProcessor.parse(jsonObject: eventJSON, in: persistenceController)
                } catch {
                    print("error parsing event from relay: \(response)")
                }
            case "NOTICE":
                print(response)
            default:
                print("got unknown response type: \(response)")
            }
        } catch {
            print("error parsing response: \(response)\nerror: \(error.localizedDescription)")
        }
    }
}
