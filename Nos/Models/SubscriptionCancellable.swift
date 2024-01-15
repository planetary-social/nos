//
//  SubscriptionCancellable.swift
//  Nos
//
//  Created by Matthew Lorentz on 12/22/23.
//

import Foundation

/// A handle that holds references to one or more `RelaySubscription`s and provides the ability to cancel these 
/// subscriptions. Will auto-cancel them when it is deallocated. Modeled after Combine's `Cancellable`.
class SubscriptionCancellable {
    private var subscriptionIDs: [RelaySubscription.ID]
    private var subscriptionCancellables = [SubscriptionCancellable]()
    private weak var relayService: RelayService?
    
    init(subscriptionIDs: [RelaySubscription.ID], relayService: RelayService) {
        self.subscriptionIDs = subscriptionIDs
        self.relayService = relayService
    }
    
    init(cancellables: [SubscriptionCancellable], relayService: RelayService) {
        self.subscriptionCancellables = cancellables
        self.subscriptionIDs = []
        self.relayService = relayService
    }
    
    private init() {
        self.subscriptionIDs = []
    }
    
    deinit {
        cancel()
    }
    
    static func empty() -> SubscriptionCancellable {
        SubscriptionCancellable()
    }
    
    func cancel() {
        relayService?.decrementSubscriptionCount(for: subscriptionIDs)
    }
}

typealias SubscriptionCancellables = [SubscriptionCancellable]
