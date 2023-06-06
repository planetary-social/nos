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

/// Manages a search query and list of results.
class SearchController: ObservableObject {
    @Published var query: String = ""
    @Published var namedAuthors = [Author]()
    @Published var authorSuggestions = [Author]()
    
    var isSearching: Bool {
        query.isEmpty
    }
    
    @Dependency(\.relayService) private var relayService
    private var cancellables = [AnyCancellable]()
    private var searchSubscriptionID: RelaySubscription.ID?
    private var context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = PersistenceController.shared.viewContext) {
        self.context = context
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
                Task { [query] in
                    if let searchSubscriptionID = self.searchSubscriptionID {
                        await self.relayService.removeSubscription(for: searchSubscriptionID)
                    }
                    let searchFilter = Filter(kinds: [.metaData], search: query)
                    self.searchSubscriptionID = await self.relayService.openSubscription(with: searchFilter)
                }
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
    
    func clear() {
        query = ""
        authorSuggestions = []
    }
}
