import Foundation
import Combine
import Dependencies
import CoreData
import Logger

/// The current state of the search.
enum SearchState {
    /// There is no text in the search field.
    case noQuery

    /// A (local) search is in progress and there are no results to display.
    case empty

    /// There are search results to display.
    case results

    /// A search is in progress.
    case loading

    /// A search is still in progress after a specified period of time.
    case stillLoading
}

/// Manages a search query and list of results.
class SearchController: ObservableObject {
    
    // MARK: - Properties
    
    /// The search query string.
    @Published var query: String = ""
    
    /// Any and all authors in the search results. As of this writing, _only_ authors appear in search results,
    /// so this contains all search results, period.
    @Published var authorResults = [Author]()

    @Published var state: SearchState = .noQuery

    @Dependency(\.router) private var router
    @Dependency(\.relayService) private var relayService
    @Dependency(\.persistenceController) private var persistenceController
    @Dependency(\.unsAPI) var unsAPI
    @Dependency(\.currentUser) var currentUser
    
    private var cancellables = [AnyCancellable]()
    private var searchSubscriptions = SubscriptionCancellables()

    /// The timer for showing the "not finding results" view. Resets any time the query is changed.
    private var timer: Timer?

    private lazy var context: NSManagedObjectContext = {
        persistenceController.viewContext
    }()

    /// The amount of time, in seconds, to remain in the `.loading` state until switching to `.stillLoading`.
    private let stillLoadingTime: TimeInterval = 10

    // MARK: - Init
    
    init() {
        $query
            .removeDuplicates()
            .map { [weak self] query in
                if query.isEmpty {
                    self?.clear()
                }
                return query
            }
            .filter { !$0.isEmpty }
            .compactMap { [weak self] query in
                guard let self else { return nil }
                self.authorResults = self.authors(named: query)
                if self.authorResults.isEmpty {
                    // if we had `results` before and don't now, we're `empty`
                    if self.state == .results {
                        self.state = .empty
                    }
                } else {
                    self.state = .results
                }
                return query
            }
            .filter { [weak self] in $0.count >= 3 || self?.state == .loading }
            .debounce(for: 0.2, scheduler: RunLoop.main)
            .sink { [weak self] query in
                self?.submitSearch(query: query)
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(
            for: NSNotification.Name.NSManagedObjectContextObjectsDidChange,
            object: context
        )
        .filter { [weak self] _ in self?.state != .noQuery }
        .compactMap { [weak self] _ in self?.query }
        .compactMap { [weak self] in self?.authors(named: $0) }
        .map { $0.sorted(by: { $0.followers.count > $1.followers.count }) }
        .sink(receiveValue: { [weak self] results in
            guard let self else { return }
            if !results.isEmpty {
                self.state = .results
            }
            self.authorResults = results
        })
        .store(in: &cancellables)
    }
    
    // MARK: - Internal
    
    func author(fromPublicKey publicKeyString: String) -> Author? {
        let strippedString = publicKeyString.trimmingCharacters(
            in: NSCharacterSet.whitespacesAndNewlines
        )
        guard let publicKey = PublicKey.build(npubOrHex: strippedString) else {
            return nil
        }
        guard let author = try? Author.findOrCreate(by: publicKey.hex, context: context) else {
            return nil
        }
        try? context.saveIfNeeded()
        return author
    }
    
    func authors(named name: String) -> [Author] {
        guard let authors = try? Author.find(named: name, context: context) else {
            return []
        }
        return authors
    }
    
    func clear() {
        state = .noQuery
        searchSubscriptions.removeAll()
        timer?.invalidate()
        query = ""
        authorResults = []
    }
    
    func note(fromPublicKey publicKeyString: String) -> Event? {
        let strippedString = publicKeyString.trimmingCharacters(
            in: NSCharacterSet.whitespacesAndNewlines
        )
        do {
            guard case let .note(eventID) = try NostrIdentifier.decode(bech32String: strippedString) else {
                return nil
            }
            guard let note = try? Event.findOrCreateStubBy(id: eventID, context: context) else {
                return nil
            }
            try? context.saveIfNeeded()
            return note
        } catch {
            return nil
        }
    }
    
    /// Searches the relays and UNS for the given query.
    /// - Parameter query: The string to search for.
    ///
    /// - Warning: SIDE EFFECT WARNING:
    /// These functions search other systems for the given query and add relevant authors to the database.
    /// The database then generates a notification which is listened to above and results are reloaded.
    func search(for query: String) {
        // if there are no results, go into the `loading` state (which will show the spinner)
        // otherwise, keep showing the results
        if state != .results {
            state = .loading
        }
        startSearchTimer()
        Task {
            self.searchSubscriptions.removeAll()
            self.searchRelays(for: query)
            self.searchUNS(for: query)
        }
    }

    func searchRelays(for query: String) {
        Task {
            let searchFilter = Filter(
                kinds: [.metaData],
                search: query,
                limit: 100,
                keepSubscriptionOpen: true
            )
            let allSearchRelays = await relayService.relayAddresses(for: currentUser) + Relay.searchOnly
            let subscription = await self.relayService.fetchEvents(
                matching: searchFilter,
                from: allSearchRelays
            )
            self.searchSubscriptions.append(subscription)
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
        timer?.invalidate()

        timer = Timer.scheduledTimer(withTimeInterval: stillLoadingTime, repeats: false) { _ in
            if !self.query.isEmpty && self.authorResults.isEmpty {
                self.state = .stillLoading
            }
        }
    }
    
    /// Searches for the value in `query`. Only needed when the user taps the Search button since typeahead search
    /// handles other use cases.
    ///
    /// First, checks to see if `query` contains the "@" symbol and if so, searches for the username with
    /// the relay service. If there's a match, shows the author.
    ///
    /// Second, checks to see if `query` matches an author's public key and if so, shows the author.
    /// 
    /// Third, checks to see if `query` matches a note's public key and if so, shows the note.
    /// 
    /// Finally, if all previous checks fail, searches the relays and UNS for the given query.
    func submitSearch(query: String) {
        searchSubscriptions.removeAll()

        let trimmedQuery = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedQuery.contains("@") {
            Task(priority: .userInitiated) {
                if let publicKeyHex =
                    await relayService.retrievePublicKeyFromUsername(trimmedQuery) {
                    Task { @MainActor in
                        router.pushAuthor(id: publicKeyHex)
                    }
                }
            }
        } else if let author = author(fromPublicKey: trimmedQuery) {
            Task { @MainActor in
                router.push(author)
            }
        } else if let note = note(fromPublicKey: trimmedQuery) {
            Task { @MainActor in
                router.push(note)
            }
        } else {
            search(for: trimmedQuery)
        }
    }
}
