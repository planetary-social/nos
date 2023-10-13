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
    private var searchSubscriptionID: RelaySubscription.ID?
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
            .map { $0.0 } // discard what the notification publisher emits.
            .debounce(for: 0.2, scheduler: RunLoop.main)
            .filter { !$0.isEmpty }
            .map { query in
                // SIDE EFFECT WARNING
                // These functions search other systems for the given query and add relevant authors to the database. 
                // The database then generates a notification which is listened to above and resulst are reloaded.
                self.searchRelays(for: query)
                self.searchUNS(for: query)
                return query
            }
            .map { self.authors(named: $0) }
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
            if let searchSubscriptionID = self.searchSubscriptionID {
                await self.relayService.decrementSubscriptionCount(for: searchSubscriptionID)
            }
            let searchFilter = Filter(kinds: [.metaData], search: query)
            self.searchSubscriptionID = await self.relayService.openSubscription(with: searchFilter)
        }
    }
    
    func searchUNS(for query: String) {
        Task {
            do {
                let matchingNames = try await unsAPI.names(matching: query)
                print(matchingNames)
                // parse names into Authors and save them to the db
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
