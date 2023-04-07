//
//  RelaySubscription.swift
//  Nos
//
//  Created by Matthew Lorentz on 4/7/23.
//

import Foundation

/// Models a request to a relay for Nostr Events. 
struct RelaySubscription: Identifiable {
    
    let filter: Filter
    
    /// The date this Filter was opened as a subscription on relays. Used to close stale subscriptions
    var subscriptionStartDate: Date?
    
    /// The number of objects using this filter. This is incremented and decremented by the RelayService to determine
    /// when a filter can be closed.
    var referenceCount: Int = 0
    
    var id: String {
        subscriptionID
    }
    
    // For closing requests; not part of hash
    var subscriptionID: String {
        filter.id
    }
    
    var isActive: Bool {
        subscriptionStartDate != nil
    }
    
    /// Returns true if this is a "one-time" filter, where we are only looking for a single event
    var isOneTime: Bool {
        filter.limit == 1
    }
}
