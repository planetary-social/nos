import Foundation
import Logger
import Combine

/// This class manages a Filter and fetches events in reverse-chronological order as `loadMore()` is called. This
/// can be used to paginate a list of events. The underlying relay subscriptions will be deallocated when this object
/// goes out of scope.  
@RelaySubscriptionManagerActor
class PagedRelaySubscription {
    let startDate: Date
    let filter: Filter
    
    private var relayService: RelayService
    private var subscriptionManager: RelaySubscriptionManager
    
    /// A set of subscriptions fetching older events.
    private var pagedSubscriptionIDs = Set<RelaySubscription.ID>()
    
    /// A set of subscriptions always listening for new events published after the `startDate`.
    private var newEventsSubscriptionIDs = Set<RelaySubscription.ID>()
    
    /// The relays we are fetching events from
    private var relayAddresses: Set<URL>
    
    /// The oldest event each relay has returned. Used to load the next page.
    private var oldestEventByRelay = [URL: Date]()
    
    private var cancellables = [AnyCancellable]()
    
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
        self.relayAddresses = relayAddresses
        Task {
            // We keep two sets of subscriptions. One is always listening for new events and the other fetches 
            // progressively older events as we page down.
            var pagedEventsFilter = filter
            pagedEventsFilter.until = startDate
            var newEventsFilter = filter
            
            newEventsFilter.since = startDate
            newEventsFilter.limit = nil
            for relayAddress in relayAddresses {
                newEventsSubscriptionIDs.insert(
                    await subscriptionManager.queueSubscription(with: filter, to: relayAddress).id
                )
            }
            loadMore()
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
            // Remove old subscriptions
            for subscriptionID in pagedSubscriptionIDs {
                relayService.decrementSubscriptionCount(for: subscriptionID)
            }
            pagedSubscriptionIDs.removeAll()
            cancellables.removeAll()
            
            // Open new subscriptions
            for relayAddress in relayAddresses {
                let newPageStartDate = oldestEventByRelay[relayAddress] ?? startDate
                var newPageFilter = self.filter
                newPageFilter.until = newPageStartDate
                newPageFilter.keepSubscriptionOpen = false
                
                let pagedEventSubscription = await subscriptionManager.queueSubscription(
                    with: newPageFilter, 
                    to: relayAddress
                )
                
                pagedEventSubscription.events.sink { [weak self] jsonEvent in
                    self?.track(event: jsonEvent, from: relayAddress)
                }
                .store(in: &cancellables)
                
                pagedSubscriptionIDs.insert(pagedEventSubscription.id)
            }
        }
    }
    
    func track(event: JSONEvent, from relay: URL) {
        if let oldestSeen = oldestEventByRelay[relay],
            event.createdDate < oldestSeen {
            oldestEventByRelay[relay] = event.createdDate
        } else {
            oldestEventByRelay[relay] = event.createdDate
        }
    }
}
