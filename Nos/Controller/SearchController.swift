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
    
    // MARK: - Properties
    
    /// The search query string.
    @Published var query: String = ""
    
    /// Any and all authors in the search results. As of this writing, _only_ authors appear in search results,
    /// so this contains all search results, period.
    @Published var authorResults = [Author]()

    /// Whether we're finding results or not, so we can show a message if not.
    @Published var isNotFindingResults = false

    @Dependency(\.router) private var router
    @Dependency(\.relayService) private var relayService
    @Dependency(\.persistenceController) private var persistenceController
    @Dependency(\.unsAPI) var unsAPI
    
    private var cancellables = [AnyCancellable]()
    private var searchSubscriptions = SubscriptionCancellables()
//    private var timerCancellables = [AnyCancellable]()
    private var timer: Timer?

    private lazy var context: NSManagedObjectContext = {
        persistenceController.viewContext
    }()
    
    // MARK: - Init
    
    init() {
        $query
            .removeDuplicates() // only do the work below when the query has changed
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
                // The database then generates a notification which is listened to above and results are reloaded.
                Task {
                    self.searchSubscriptions.removeAll()
                    self.searchRelays(for: query)
                    self.searchUNS(for: query)
                }
                return query
            }
            .map { self.authors(named: $0) } // this and below need to run every time the context changes
            .map { $0.sorted(by: { $0.followers.count > $1.followers.count }) }
            .sink(receiveValue: { results in
                if !results.isEmpty {
                    self.isNotFindingResults = false
                }
                self.authorResults = results
            })
            .store(in: &cancellables)

        $query
            .removeDuplicates()
            .sink { query in
                if query.isEmpty {
                    self.isNotFindingResults = false
                    self.timer?.invalidate()
//                    self.timerCancellables.removeAll()
                } else {
                    self.startSearchTimer()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Internal
    
    func author(fromPublicKey publicKeyString: String) -> Author? {
        let strippedString = publicKeyString.trimmingCharacters(
            in: NSCharacterSet.whitespacesAndNewlines
        )
        guard let publicKey = PublicKey(npub: strippedString) ?? PublicKey(hex: strippedString) else {
            return nil
        }
        guard let author = try? Author.findOrCreate(by: publicKey.hex, context: context) else {
            return nil
        }
        try? context.saveIfNeeded()
        return author
    }
    
    func authors(named name: String) -> [Author] {
        if let publicKey = PublicKey(npub: name),
            let author = try? Author.findOrCreate(by: publicKey.hex, context: context) {
            Task { @MainActor in
                router.push(author)
            }
            clear()
            return []
        }
        guard let authors = try? Author.find(named: name, context: context) else {
            return []
        }

        return authors
    }
    
    func clear() {
        query = ""
        authorResults = []
        isNotFindingResults = false
//        timerCancellables.removeAll()
        timer?.invalidate()
    }
    
    func note(fromPublicKey publicKeyString: String) -> Event? {
        let strippedString = publicKeyString.trimmingCharacters(
            in: NSCharacterSet.whitespacesAndNewlines
        )
        guard let publicKey = PublicKey(note: strippedString) else {
            return nil
        }
        guard let note = try? Event.findOrCreateStubBy(id: publicKey.hex, context: context) else {
            return nil
        }
        try? context.saveIfNeeded()
        return note
    }

    func searchRelays(for query: String) {
        Task {
            let searchFilter = Filter(kinds: [.metaData], search: query, limit: 100)
            self.searchSubscriptions.append(await self.relayService.subscribeToEvents(matching: searchFilter))
        }
    }
    
    func searchUNS(for query: String) {
        Task {
            do {
                let pubKeys = try await unsAPI.names(matching: query)
                try Task.checkCancellation()
                try await self.context.perform {
                    for pubKey in pubKeys {
                        let author = try Author.findOrCreate(by: pubKey, context: self.context)
                        author.uns = query
                    }
                }
                try self.context.saveIfNeeded()
                for pubKey in pubKeys {
                    try Task.checkCancellation()
                    searchSubscriptions.append(await relayService.requestMetadata(for: pubKey, since: nil))
                }
            } catch {
                Log.optional(error)
            }
        }
    }

    func startSearchTimer() {
        isNotFindingResults = false
//        timerCancellables.removeAll()
        timer?.invalidate()

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
            if !self.query.isEmpty && self.authorResults.isEmpty {
                self.isNotFindingResults = true
//                self.timerCancellables.removeAll()
            }
        }


//        Timer.publish(every: 10, on: .main, in: .common)
//            .autoconnect()
//            .sink { _ in
//                if !self.query.isEmpty && self.authorResults.isEmpty {
//                    self.isNotFindingResults = true
//                    self.timerCancellables.removeAll()
//                }
//            }
//            .store(in: &timerCancellables)
    }

    func submitSearch() { // rename to seeIfThisIsSomeSortOfIdentifier (or maybe put this all into .map)
        if query.contains("@") {
            Task(priority: .userInitiated) {
                if let publicKeyHex =
                    await relayService.retrievePublicKeyFromUsername(query.lowercased()) {
                    Task { @MainActor in
                        if let author = author(fromPublicKey: publicKeyHex) {
                            router.push(author)
                        }
                    }
                }
            }
        } else {
            if let author = author(fromPublicKey: query) {
                Task { @MainActor in
                    router.push(author)
                }
            } else if let note = note(fromPublicKey: query) {
                Task { @MainActor in
                    router.push(note)
                }
            }
        }
    }
}
