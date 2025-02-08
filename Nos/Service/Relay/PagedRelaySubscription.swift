import Foundation
import Logger
import Combine

/// This class manages a Filter and fetches events in reverse-chronological order as `loadMore()` is called. This
/// can be used to paginate a list of events. The underlying relay subscriptions will be deallocated when this object
/// goes out of scope.  
///
/// Paging in Nostr is very different from traditional HTTP paging, because we can't just ask for "the next 20 events
/// after index 100". Instead we have to use dates and ask for "the next 20 events older than X". Moreover because we
/// are fetching from a lot of relays the date X is different for every relay. `PagedRelaySubscription` abstracts away
/// these details, so the caller basically only needs to know what kinds of events they want from what relays, and then
/// call `loadMore()` whenever the user scrolls a page.
@RelaySubscriptionManagerActor
final class PagedRelaySubscription {
    private let startDate: Date
    private let filter: Filter
    
    private let relayService: RelayService
    private let subscriptionManager: RelaySubscriptionManager
    
    /// A set of subscriptions fetching older events.
    private var pagedSubscriptionIDs = Set<RelaySubscription.ID>()
    
    /// A set of subscriptions always listening for new events published after the `startDate`.
    private var newEventsSubscriptionIDs = Set<RelaySubscription.ID>()
    
    /// The relays we are fetching events from
    private let relayAddresses: Set<URL>
    
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
            var newEventsFilter = filter
            newEventsFilter.since = startDate
            newEventsFilter.keepSubscriptionOpen = true
            newEventsFilter.limit = nil
            for relayAddress in relayAddresses {
                newEventsSubscriptionIDs.insert(
                    await subscriptionManager.queueSubscription(with: newEventsFilter, to: relayAddress).id
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
    
    /// Instructs the pager to load the next page of events from each relay. The given date should be roughly the date
    /// of the content the user is looking at and is used to put a given realy into "catch up" mode where we fetch
    /// more events to catch up what the user is looking at.
    func loadMore(displayingContentAt displayedDate: Date? = nil) {
        Task { [self] in
            // Remove old subscriptions
            for subscriptionID in pagedSubscriptionIDs {
                relayService.decrementSubscriptionCount(for: subscriptionID)
            }
            pagedSubscriptionIDs.removeAll()
            cancellables.removeAll()
            
            // Open new subscriptions
            for relayAddress in relayAddresses {
                
                // To fetch the next "page" we need to know what the last event we got was, then we ask for the next
                // `limit` events older than that.
                let nextPageStartDate = oldestEventByRelay[relayAddress] ?? startDate
                var nextPageFilter = self.filter
                nextPageFilter.until = nextPageStartDate
                nextPageFilter.keepSubscriptionOpen = false
                
                // If the most recent event we got is older than what the user is looking at, open an extra subscription
                // with no limit so we can "catch up".
                if let displayedDate, nextPageStartDate >= displayedDate {
                    var catchUpFilter = nextPageFilter
                    catchUpFilter.since = displayedDate
                    catchUpFilter.until = nextPageStartDate
                    catchUpFilter.limit = nil
                    let catchUpSubscription = await subscriptionManager.queueSubscription(
                        with: nextPageFilter, 
                        to: relayAddress
                    )
                    pagedSubscriptionIDs.insert(catchUpSubscription.id)
                    
                    nextPageFilter.until = displayedDate
                }
                
                let nextPageSubscription = await subscriptionManager.queueSubscription(
                    with: nextPageFilter, 
                    to: relayAddress
                )
                
                /// Keep track of the oldest event seen for this relay so we can use it when it's time to load the next
                /// page.
                nextPageSubscription.events
                    .sink { [weak self] jsonEvent in
                        Task {
                            await self?.track(event: jsonEvent, from: relayAddress)
                        }
                    }
                    .store(in: &cancellables)
                
                pagedSubscriptionIDs.insert(nextPageSubscription.id)
                
                await subscriptionManager.processSubscriptionQueue()
            }
        }
    }
    
    /// Used to record the oldest event we've seen from a relay. We need this because `track(event:from:)` is 
    /// nonisolated so it can be called from a Combine chain.
    private func updateOldestEvent(for relay: URL, to date: Date) {
        oldestEventByRelay[relay] = date
    }
    
    /// Records the `created_at` date from given event if it's the oldest one we've seen so far. This information
    /// is needed to load the next page when it's time. 
    nonisolated private func track(event: JSONEvent, from relay: URL) async {
        if let oldestSeen = await oldestEventByRelay[relay] {
            if event.createdDate < oldestSeen {
                await updateOldestEvent(for: relay, to: event.createdDate)
            }
        } else {
            await updateOldestEvent(for: relay, to: event.createdDate)
        }
    }
}
