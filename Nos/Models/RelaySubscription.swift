import Foundation
import Logger
import Combine

/// Models a request to a relay for Nostr Events. 
final class RelaySubscription: Identifiable, Hashable {
    
    let id: String
    
    let filter: Filter
    
    /// The relay this Filter should be sent to.
    let relayAddress: URL
    
    /// The date this Filter was opened as a subscription on relays. Used to close stale subscriptions
    var subscriptionStartDate: Date?
    
    /// The number of events that have been returned for this subscription
    var receivedEventCount = 0
    
    /// The number of objects using this filter. This is incremented and decremented by the RelayService to determine
    /// when a filter can be closed.
    var referenceCount: Int = 0
    
    /// An observable stream of events that should emit every event downloaded on this subscription 
    let events = PassthroughSubject<JSONEvent, Never>()
    
    var isActive: Bool {
        subscriptionStartDate != nil
    }
    
    /// Whether this RelaySubscription should close the subscription to the
    /// filter after receiving a response.
    var closesAfterResponse: Bool {
        !filter.keepSubscriptionOpen
    }
    
    internal init(
        filter: Filter, 
        relayAddress: URL, 
        subscriptionStartDate: Date? = nil, 
        referenceCount: Int = 0
    ) {
        self.filter = filter
        self.relayAddress = relayAddress
        // Compute a unique ID but predictable ID. The sha256 cuts the length down to an acceptable size.
        self.id = (filter.id + "-" + relayAddress.absoluteString).data(using: .utf8)?.sha256 ?? "error"
        self.subscriptionStartDate = subscriptionStartDate
        self.referenceCount = referenceCount
    }
    
    static func == (lhs: RelaySubscription, rhs: RelaySubscription) -> Bool {
        lhs.id == rhs.id &&
        lhs.filter == rhs.filter &&
        lhs.relayAddress == rhs.relayAddress &&
        lhs.subscriptionStartDate == rhs.subscriptionStartDate &&
        lhs.referenceCount == rhs.referenceCount &&
        lhs.isActive == rhs.isActive
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(filter)
        hasher.combine(relayAddress)
        hasher.combine(subscriptionStartDate)
        hasher.combine(referenceCount)
        hasher.combine(isActive)
    }
}
