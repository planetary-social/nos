//
//  PaginatedEventController.swift
//  Nos
//
//  Created by Matthew Lorentz on 4/11/23.
//

import Foundation
import CoreData
import SwiftUI
import Dependencies

class PaginatedHomeFeedDataSource: ObservableObject {

    @Published var eventIDs = [String]()
    
    @Dependency(\.relayService) private var relayService

    var date = Date.now
    
    private var context: NSManagedObjectContext = PersistenceController.shared.newBackgroundContext()
    
    private var subscriptionIds: [String] = []
    
    var user: Author? {
        didSet {
            load(refresh: true)
        }
    }
    
    init() {
    }
    
    deinit {
        Task(priority: .userInitiated) {
            await relayService.removeSubscriptions(for: subscriptionIds)
            subscriptionIds.removeAll()
        }
    }
    
    private var fetchLimit = 30
    private var fetchOffset = 0
    
    func load(refresh: Bool = false) {
        if let user {
            Task { @MainActor in
                let newEventIDs = try! await self.context.perform {
                    try self.context.fetch(
                        Event.homeFeed(
                            for: user, 
                            after: self.date, 
                            limit: self.fetchLimit, 
                            offset: self.fetchOffset
                        )
                    )
                    .compactMap { $0.identifier }
                }
                if refresh {
                    self.eventIDs = newEventIDs
                } else {
                    self.eventIDs += newEventIDs
                }
            }
        }
    }
    
    @MainActor func loadMore() async {
        fetchOffset += fetchLimit
        load()
    }
    
    @MainActor func refreshHomeFeed() async {
        date = .now
        fetchOffset = 0
        load(refresh: true)

        // Close out stale requests
        if !subscriptionIds.isEmpty {
            await relayService.removeSubscriptions(for: subscriptionIds)
            subscriptionIds.removeAll()
        }

        // I can't figure out why but the home feed doesn't update when you follow someone without this.
        //            if let currentUserKey = user?.hexadecimalPublicKey {
        // swiftlint:disable line_length
        //                events.nsPredicate = NSPredicate(format: "kind = 1 AND SUBQUERY(eventReferences, $reference, $reference.marker = 'root' OR $reference.marker = 'reply' OR $reference.marker = nil).@count = 0 AND ANY author.followers.source.hexadecimalPublicKey = %@", currentUserKey)
        // swiftlint:enable line_length
        //            }

        if let follows = await CurrentUser.shared.follows {
            let authors = follows.keys

            if !authors.isEmpty {
                let textFilter = Filter(authorKeys: authors, kinds: [.text, .delete], limit: 100)
                let textSub = await relayService.openSubscription(with: textFilter)
                subscriptionIds.append(textSub)
            }
            if let currentUser = user {
                let currentUserAuthorKeys = [currentUser.hexadecimalPublicKey!]
                let userLikesFilter = Filter(
                    authorKeys: currentUserAuthorKeys,
                    kinds: [.like, .delete],
                    limit: 100
                )
                let userLikesSub = await relayService.openSubscription(with: userLikesFilter)
                subscriptionIds.append(userLikesSub)
            }
        }
    }
    
}
