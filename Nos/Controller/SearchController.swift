//
//  SearchController.swift
//  Nos
//
//  Created by Matthew Lorentz on 6/5/23.
//

import Foundation
import Combine
import Dependencies
import CoreData
import Logger

/// Manages a search query and list of results.
class SearchController: ObservableObject {
    @Published var query: String = ""
    @Published var namedAuthors = [Author]()
    @Published var authorSuggestions = [Author]()
    
    var isSearching: Bool {
        query.isEmpty
    }
    
    @Dependency(\.relayService) private var relayService
    @Dependency(\.persistenceController) private var persistenceController
    @Dependency(\.unsAPI) var unsAPI
    private var cancellables = [AnyCancellable]()
    private var searchSubscriptions = [RelaySubscription.ID]()
    private lazy var context: NSManagedObjectContext = {
        persistenceController.viewContext
    }()
    
    init() {
        $query
            .combineLatest(
                // listen for new objects, as this is how we get search results from relays
                NotificationCenter.default.publisher(
                    for: NSNotification.Name.NSManagedObjectContextObjectsDidChange,
                    object: context
                )
            )
            .map { $0.0.lowercased() } 
            .debounce(for: 0.2, scheduler: RunLoop.main)
            .filter { !$0.isEmpty }
            .map { query in
                // SIDE EFFECT WARNING
                // These functions search other systems for the given query and add relevant authors to the database. 
                // The database then generates a notification which is listened to above and resulst are reloaded.
                Task { 
                    await self.relayService.decrementSubscriptionCount(for: self.searchSubscriptions)
                    self.searchSubscriptions = []
                    self.searchRelays(for: query)
                    self.searchUNS(for: query)
                }
                return query
            }
            .map { self.authors(named: $0) }
            .map { $0.sorted(by: { $0.followers.count > $1.followers.count }) }
            .sink(receiveValue: { self.authorSuggestions = $0 })
            .store(in: &cancellables)
    }
    
    func authors(named name: String) -> [Author] {
        guard let authors = try? Author.find(named: name, context: context) else {
            return []
        }

        return authors
    }
    
    func searchRelays(for query: String) {
        Task {
            let searchFilter = Filter(kinds: [.metaData], search: query, limit: 100)
            self.searchSubscriptions.append(await self.relayService.openSubscription(with: searchFilter))
        }
    }
    
    func searchUNS(for query: String) {
        Task {
            do {
                let pubKeys = try await unsAPI.names(matching: query)
                try Task.checkCancellation()
                try await self.context.perform {
                    for pubKey in pubKeys {
                        let author = try Author().findOrCreate(by: pubKey, context: self.context)
                        author.uns = query
                    }
                }
                try self.context.saveIfNeeded()
                for pubKey in pubKeys {
                    try Task.checkCancellation()
                    if let subscriptionID = await relayService.requestMetadata(for: pubKey, since: nil) {
                        searchSubscriptions.append(subscriptionID)
                    }
                }
            } catch {
                Log.optional(error)
            }
        }
    }
    
    func clear() {
        query = ""
        authorSuggestions = []
    }
}
