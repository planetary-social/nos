//
//  RelaySubscription.swift
//  Nos
//
//  Created by Matthew Lorentz on 4/7/23.
//

import Foundation

/// Models a request to a relay for Nostr Events. 
struct RelaySubscription: Identifiable {
    
    var id: String 
    
    let filter: Filter
    
    /// The relay this Filter should be sent to.
    let relayAddress: URL
    
    /// The date this Filter was opened as a subscription on relays. Used to close stale subscriptions
    var subscriptionStartDate: Date?
    
    var oldestEventCreationDate: Date?
    
    /// The number of objects using this filter. This is incremented and decremented by the RelayService to determine
    /// when a filter can be closed.
    var referenceCount: Int = 0
    
    var isActive: Bool {
        subscriptionStartDate != nil
    }
    
    /// Returns true if this is a "one-time" filter, where we are only looking for a single event
    var isOneTime: Bool {
        filter.limit == 1
    }
    
    internal init(filter: Filter, relayAddress: URL, subscriptionStartDate: Date? = nil, oldestEventCreationDate: Date? = nil, referenceCount: Int = 0) {
        self.filter = filter
        self.relayAddress = relayAddress
        self.id = (filter.id + "-" + relayAddress.absoluteString).sha256()
        self.subscriptionStartDate = subscriptionStartDate
        self.oldestEventCreationDate = oldestEventCreationDate
        self.referenceCount = referenceCount
    }
}
