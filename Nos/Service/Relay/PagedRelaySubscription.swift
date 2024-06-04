import Foundation
import Logger

/// This class manages a Filter and fetches events in reverse-chronological order as `loadMore()` is called. This
/// can be used to paginate a list of events. The underlying relay subscriptions will be deallocated when this object
/// goes out of scope. 
class PagedRelaySubscription {
    let startDate: Date
    let filter: Filter
    
    private var relayService: RelayService
    private var subscriptionManager: RelaySubscriptionManager
    
    /// A set of subscriptions fetching older events.
    private var pagedSubscriptionIDs = Set<RelaySubscription.ID>()
    
    /// A set of subscriptions always listening for new events published after the `startDate`.
    private var newEventsSubscriptionIDs = Set<RelaySubscription.ID>()
    
    init(
        startDate: Date, 
        filter: Filter, 
        relayService: RelayService,
        subscriptionManager: RelaySubscriptionManager, 
        relayAddresses: Set<URL>
    ) {
        self.startDate = startDate
        self.filter = filter
        self.relayService = relayService
        self.subscriptionManager = subscriptionManager
        Task {
            // We keep two sets of subscriptions. One is always listening for new events and the other fetches 
            // progressively older events as we page down.
            var pagedEventsFilter = filter
            pagedEventsFilter.until = startDate
            var newEventsFilter = filter
            newEventsFilter.since = startDate
            for relayAddress in relayAddresses {
                newEventsSubscriptionIDs.insert(
                    await subscriptionManager.queueSubscription(with: filter, to: relayAddress)
                )
                pagedSubscriptionIDs.insert(
                    await subscriptionManager.queueSubscription(with: pagedEventsFilter, to: relayAddress)
                )
            }
        }
    }
    
    deinit {
        for subscriptionID in newEventsSubscriptionIDs {
            relayService.decrementSubscriptionCount(for: subscriptionID)
        }
        
        for subscriptionID in pagedSubscriptionIDs {
            relayService.decrementSubscriptionCount(for: subscriptionID)
        }
    }
    
    /// Instructs the pager to load older events for the given `filter` by decrementing the `until` parameter on the 
    /// `Filter` and updating all its managed subscriptions.
    func loadMore() {
        Task { [self] in
            var newUntilDates = [URL: Date]()
            var subscriptionsToRemove = Set<RelaySubscription.ID>()
            
            for subscriptionID in pagedSubscriptionIDs {
                if let subscription = await subscriptionManager.subscription(from: subscriptionID),
                    let newDate = subscription.oldestEventCreationDate {
                    
                    guard newDate != subscription.filter.until else {
                        // Optimization. Don't close and reopen an identical filter.
                        continue
                    }
                          
                    newUntilDates[subscription.relayAddress] = newDate
                    await subscriptionManager.decrementSubscriptionCount(for: subscriptionID)
                    subscriptionsToRemove.insert(subscription.id)
                }
            }
            
            pagedSubscriptionIDs.subtract(subscriptionsToRemove)            
            
            for (relayAddress, until) in newUntilDates {
                var newEventsFilter = self.filter
                newEventsFilter.until = until
                pagedSubscriptionIDs.insert(
                    await subscriptionManager.queueSubscription(with: newEventsFilter, to: relayAddress)
                )
            }
        }
    }
}
