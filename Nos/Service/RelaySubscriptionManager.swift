//
//  RelaySubscriptionManager.swift
//  Nos
//
//  Created by Matthew Lorentz on 4/7/23.
//

import Starscream

/// An actor that manages state for a `RelayService` including lists of open sockets and subscriptions.
actor RelaySubscriptionManager {
    
    var all = [RelaySubscription]()
    
    var sockets = [WebSocket]()
    
    var active: [RelaySubscription] {
        all
            .filter { $0.isActive }
    }
    
    func subscription(from filter: Filter) -> RelaySubscription? {
        subscription(from: filter.id)
    }
    
    func subscription(from subscriptionID: RelaySubscription.ID) -> RelaySubscription? {
        if let subscriptionIndex = self.all.firstIndex(where: { $0.id == subscriptionID }) {
            return all[subscriptionIndex]
        } else {
            return nil
        }
    }
    
    func updateSubscriptions(with newValue: RelaySubscription) {
        if let subscriptionIndex = self.all.firstIndex(where: { $0.id == newValue.id }) {
            all[subscriptionIndex] = newValue
        } else {
            all.append(newValue)
        }
    }
    
    func removeSubscription(with subscriptionID: RelaySubscription.ID) {
        if let subscriptionIndex = self.all.firstIndex(
            where: { $0.id == subscriptionID }
        ) {
            all.remove(at: subscriptionIndex)
        }
    }
    
    func addSocket(for relayAddress: URL) -> WebSocket? {
        guard !sockets.contains(where: { $0.request.url == relayAddress }) else {
            return nil
        }
            
        var request = URLRequest(url: relayAddress)
        request.timeoutInterval = 10
        let socket = WebSocket(request: request, compressionHandler: .none)
        sockets.append(socket)
        return socket
    }
    
    func close(socket: WebSocket) {
        socket.disconnect()
        if let index = sockets.firstIndex(where: { $0 === socket }) {
            sockets.remove(at: index)
        }
    }
    
    func remove(_ socket: WebSocketClient) {
        if let index = sockets.firstIndex(where: { $0 === socket }) {
            sockets.remove(at: index)
        }
    }
    
    func socket(for address: String) -> WebSocket? {
        if let index = sockets.firstIndex(where: { $0.request.url!.absoluteString == address }) {
            return sockets[index]
        }
        return nil
    }
}
