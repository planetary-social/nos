//
//  RelaySubscriptionManager.swift
//  Nos
//
//  Created by Matthew Lorentz on 4/7/23.
//

import Starscream
import Foundation
import Logger

/// An actor that manages state for a `RelayService` including lists of open sockets and subscriptions.
actor RelaySubscriptionManager {
    
    // MARK: - Public Properties
    
    var all = [RelaySubscription]()
    
    var sockets = [WebSocket]()
    
    var active: [RelaySubscription] {
        all.filter { $0.isActive }
    }
    
    // MARK: - Mutating the list of subscriptions
    
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
    
    private func updateSubscriptions(with newValue: RelaySubscription) {
        if let subscriptionIndex = self.all.firstIndex(where: { $0.id == newValue.id }) {
            all[subscriptionIndex] = newValue
        } else {
            all.append(newValue)
        }
    }
    
    private func removeSubscription(with subscriptionID: RelaySubscription.ID) {
        if let subscriptionIndex = self.all.firstIndex(
            where: { $0.id == subscriptionID }
        ) {
            all.remove(at: subscriptionIndex)
        }
    }
    
    func forceCloseSubscriptionCount(for subscriptionID: RelaySubscription.ID) {
        removeSubscription(with: subscriptionID)
    }
    
    func decrementSubscriptionCount(for subscriptionID: RelaySubscription.ID) async -> Bool {
        if var subscription = subscription(from: subscriptionID) {
            if subscription.referenceCount == 1 {
                removeSubscription(with: subscriptionID)
                return false
            } else {
                subscription.referenceCount -= 1
                updateSubscriptions(with: subscription)
                return true
            }
        }
        return false
    }
    
    /// Finds stale subscriptions, removes them from the subscription list, and returns them.
    func staleSubscriptions() async -> [RelaySubscription] {
        var staleSubscriptions = [RelaySubscription]()
        for subscription in active {
            if subscription.isOneTime, 
                let filterStartedAt = subscription.subscriptionStartDate,
                filterStartedAt.distance(to: .now) > 5 {
                staleSubscriptions.append(subscription)
            }
        }
        for subscription in staleSubscriptions {
            forceCloseSubscriptionCount(for: subscription.subscriptionID)
        }
        return staleSubscriptions
    }

    func addSocket(for relayAddress: URL) -> WebSocket? {
        guard !sockets.contains(where: { $0.request.url == relayAddress }) else {
            return nil
        }
        
        var request = URLRequest(url: relayAddress)
        request.timeoutInterval = 10
        let socket = WebSocket(request: request)
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
    
    func socket(for url: URL) -> WebSocket? {
        if let index = sockets.firstIndex(where: { $0.request.url == url }) {
            return sockets[index]
        }
        return nil
    }
    
    // MARK: - Talking to Relays
    
    private let subscriptionLimit = 10
    private let minimimumOneTimeSubscriptions = 1
    
    func processSubscriptionQueue(relays: [URL]) async {
        
        // TODO: Make sure active subscriptions are open on all relays
        
        // Strategy: we have two types of subscriptions: long and one time. We can only have a certain number of
        // subscriptions open at once. We want to:
        // - Open as many long running subsriptions as we can, leaving room for `minimumOneTimeSubscriptions`
        // - fill remaining slots with one time filters
        let waitingLongSubscriptions = all.filter { !$0.isOneTime && !$0.isActive }
        let waitingOneTimeSubscriptions = all.filter { $0.isOneTime && !$0.isActive }
        let openSlots = subscriptionLimit - active.count
        let openLongSlots = max(0, openSlots - minimimumOneTimeSubscriptions)
        
        for subscription in waitingLongSubscriptions.prefix(openLongSlots) {
            start(subscription: subscription, relays: relays)
        }
        
        let openOneTimeSlots = max(0, subscriptionLimit - active.count)
        
        for subscription in waitingOneTimeSubscriptions.prefix(openOneTimeSlots) {
            start(subscription: subscription, relays: relays)
        }
        
        Log.debug("\(active.count) active subscriptions. \(all.count - active.count) subscriptions waiting in queue.")
    }
    
    func queueSubscription(with filter: Filter, to overrideRelays: [URL]? = nil) async -> RelaySubscription.ID {
        var subscription: RelaySubscription
        
        if let existingSubscription = self.subscription(from: filter.id) {
            // dedup
            subscription = existingSubscription
        } else {
            subscription = RelaySubscription(filter: filter)
        }
        subscription.referenceCount += 1
        updateSubscriptions(with: subscription)
        
        return subscription.id
    }
    
    private func start(subscription: RelaySubscription, relays: [URL]) {
        var subscription = subscription
        subscription.subscriptionStartDate = .now
        updateSubscriptions(with: subscription)
        Log.debug("starting subscription: \(subscription.id), filter: \(subscription.filter)")
        relays.forEach { relayURL in
            if let socket = socket(for: relayURL) {
                requestEvents(from: socket, subscription: subscription)
            }
        }
    }
    
    /// Takes a RelaySubscription model and makes a websockets request to the given socket
    func requestEvents(from socket: WebSocketClient, subscription: RelaySubscription) {
        do {
            // Track this so we can close requests if needed
            let request: [Any] = ["REQ", subscription.id, subscription.filter.dictionary]
            let requestData = try JSONSerialization.data(withJSONObject: request)
            let requestString = String(data: requestData, encoding: .utf8)!
            Log.debug("REQ for \(subscription.id) sent to \(socket.host)")
            socket.write(string: requestString)
        } catch {
            Log.error("Error: Could not send request \(error.localizedDescription)")
        }
    }
}
