import Foundation
import Logger

/// Models a request to a relay for Nostr Events. 
struct RelaySubscription: Identifiable, Hashable {
    
    var id: String 
    
    let filter: Filter
    
    /// The relay this Filter should be sent to.
    let relayAddress: URL
    
    /// The date this Filter was opened as a subscription on relays. Used to close stale subscriptions
    var subscriptionStartDate: Date?
    
    /// The oldest creation date on an event processed by this filter. Used for pagination.
    var oldestEventCreationDate: Date?
    
    /// The number of events that have been returned for this subscription
    var receivedEventCount = 0
    
    /// The number of objects using this filter. This is incremented and decremented by the RelayService to determine
    /// when a filter can be closed.
    var referenceCount: Int = 0
    
    var isActive: Bool {
        subscriptionStartDate != nil
    }
    
    /// Whether this RelaySubscription should close the subscription to the
    /// filter after receiving a response.
    /// stored events (if false).
    var closesAfterResponse: Bool {
        !filter.keepSubscriptionOpen
    }
    
    internal init(
        filter: Filter, 
        relayAddress: URL, 
        subscriptionStartDate: Date? = nil, 
        oldestEventCreationDate: Date? = nil, 
        referenceCount: Int = 0
    ) {
        self.filter = filter
        self.relayAddress = relayAddress
        // Compute a unique ID but predictable ID. The sha256 cuts the length down to an acceptable size.
        self.id = (filter.id + "-" + relayAddress.absoluteString).data(using: .utf8)?.sha256 ?? "error"
        self.subscriptionStartDate = subscriptionStartDate
        self.oldestEventCreationDate = oldestEventCreationDate
        self.referenceCount = referenceCount
    }
}
