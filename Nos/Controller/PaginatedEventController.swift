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

    @Published var events = [Event]()
    
    @Dependency(\.relayService) private var relayService

    var date = Date.now
    
    private var context: NSManagedObjectContext = PersistenceController.shared.viewContext
    
    private var subscriptionIds: [String] = []
    
    var user: Author? {
        didSet {
            events = []
            load()
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
    
    private var fetchLimit = 17
    private var fetchOffset = 0
    
    func load() {
        if let user {
            events += try! context.fetch(Event.homeFeed(for: user, after: date, limit: fetchLimit, offset: fetchOffset))
        }
    }
    
    @MainActor func loadMore() async {
        fetchOffset += fetchLimit
        load()
    }
    
    func refreshHomeFeed() {
        Task(priority: .userInitiated) { @MainActor in
            date = .now
            fetchOffset = 0
            events = []
            load()
            
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
    
}
