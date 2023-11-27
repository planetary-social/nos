//
//  PagedRelaySubscription.swift
//  Nos
//
//  Created by Matthew Lorentz on 11/27/23.
//

import Foundation
import Logger

/// This class manages a Filter and fetches events in reverse-chronological order as `loadMore()` is called. This
/// can be used to paginate a list of events. 
class PagedRelaySubscription {
    var startDate: Date
    let filter: Filter
    
    private var subscriptionManager: RelaySubscriptionManager
    private var subscriptionIDs = [RelaySubscription.ID]()
    
    init(startDate: Date, filter: Filter, subscriptionManager: RelaySubscriptionManager, relayAddresses: [URL]) {
        self.startDate = startDate
        self.filter = filter
        self.subscriptionManager = subscriptionManager
        Task {
            var newEventsFilter = filter
            newEventsFilter.until = startDate
            for relayAddress in relayAddresses {
                subscriptionIDs.append(
                    await subscriptionManager.queueSubscription(with: newEventsFilter, to: relayAddress)
                )
            }
        }
    }
    
    /// Instructs the pager to load older events for the given `filter` by decrementing the `until` parameter on the 
    /// `Filter` and updating all its managed subscriptions.
    func loadMore() {
        Task { [self] in
            var newUntilDates = [URL: Date]()
            
            for subscriptionID in subscriptionIDs {
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
                subscriptionIDs.append(
                    await subscriptionManager.queueSubscription(with: newEventsFilter, to: relayAddress)
                )
            }
        }
    }
}
