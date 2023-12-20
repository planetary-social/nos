//
//  PagedRelaySubscription.swift
//  Nos
//
//  Created by Matthew Lorentz on 11/27/23.
//

import Foundation
import Logger

/// This class manages a Filter and fetches events in reverse-chronological order as `loadMore()` is called. This
/// can be used to paginate a list of events. The underlying relay subscriptions will be deallocated when this object
/// goes out of scope. 
class PagedRelaySubscription {
    let startDate: Date
    let filter: Filter
    
    private var subscriptionManager: RelaySubscriptionManager
    private var pagedSubscriptionIDs = [RelaySubscription.ID]()
    private var newEventsSubscriptionIDs = [RelaySubscription.ID]()
    
    init(startDate: Date, filter: Filter, subscriptionManager: RelaySubscriptionManager, relayAddresses: [URL]) {
        self.startDate = startDate
        self.filter = filter
        self.subscriptionManager = subscriptionManager
        Task {
            // We have two types of subscriptions. The new events
            var pagedEventsFilter = filter
            pagedEventsFilter.until = startDate
            var newEventsFilter = filter
            newEventsFilter.since = startDate
            for relayAddress in relayAddresses {
                newEventsSubscriptionIDs.append(
                    await subscriptionManager.queueSubscription(with: filter, to: relayAddress)
                )
                pagedSubscriptionIDs.append(
                    await subscriptionManager.queueSubscription(with: pagedEventsFilter, to: relayAddress)
                )
            }
        }
    }
    
    deinit {
        Task.detached { [newEventsSubscriptionIDs, pagedSubscriptionIDs, subscriptionManager] in
            // TODO: are these subscriptions being fully closed? I think we aren't sending a CLOSE message
            for subscriptionID in newEventsSubscriptionIDs {
                await subscriptionManager.decrementSubscriptionCount(for: subscriptionID)
            }
            
            for subscriptionID in pagedSubscriptionIDs {
                await subscriptionManager.decrementSubscriptionCount(for: subscriptionID)
            }
        }
    }
    
    /// Instructs the pager to load older events for the given `filter` by decrementing the `until` parameter on the 
    /// `Filter` and updating all its managed subscriptions.
    func loadMore() {
        Task { [self] in
            var newUntilDates = [URL: Date]()
            
            for subscriptionID in pagedSubscriptionIDs {
                if let subscription = await subscriptionManager.subscription(from: subscriptionID),
                    let newDate = subscription.oldestEventCreationDate {
                    newUntilDates[subscription.relayAddress] = newDate
                    await subscriptionManager.decrementSubscriptionCount(for: subscriptionID)
                    Log.debug("Oldest event from \(subscriptionID) is \(newDate)")
                }
            }
            
            for (relayAddress, until) in newUntilDates {
                var newEventsFilter = self.filter
                newEventsFilter.until = until
                pagedSubscriptionIDs.append(
                    await subscriptionManager.queueSubscription(with: newEventsFilter, to: relayAddress)
                )
            }
        }
    }
}
