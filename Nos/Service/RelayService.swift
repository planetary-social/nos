//
//  RelayService.swift
//  Nos
//
//  Created by Matthew Lorentz on 2/1/23.
//

import Foundation
import Starscream
import CoreData

class RelayService: WebSocketDelegate, ObservableObject {
    
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
    
    func didReceive(event: WebSocketEvent, client: WebSocketClient) {
        switch event {
        case .connected(let headers):
            print("websocket is connected: \(headers)")
            requestEvents(from: client)
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
        case .ping(_):
            break
        case .pong(_):
            break
        case .viabilityChanged(_):
            break
        case .reconnectSuggested(_):
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
    
    func requestEvents(from client: WebSocketClient) {
        do {
            let request: [Any] = ["REQ", UUID().uuidString, ["limit": 100]]
            let requestData = try JSONSerialization.data(withJSONObject: request)
            let requestString = String(data: requestData, encoding: .utf8)!
            client.write(string: requestString)
        } catch {
            print("could not send request \(error.localizedDescription)")
        }
    }
    
    func requestEventsFromAll() {
        openSocketsForRelays()
        sockets.forEach { requestEvents(from: $0) }
    }
    
    func publish(_ event: Event) throws {
        let eventMessageJSON = ["EVENT", event.jsonRepresentation] as [Any]
        let eventMessageData = try JSONSerialization.data(withJSONObject: eventMessageJSON, options: .withoutEscapingSlashes)
        let eventMessageString = String(data: eventMessageData, encoding: .utf8)!
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
            let jsonResponse = try JSONSerialization.jsonObject(with: response.data(using: .utf8)!)
            guard let responseArray = jsonResponse as? Array<Any>,
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
                    _ = try Event.parse(jsonObject: eventJSON, in: persistenceController)
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

