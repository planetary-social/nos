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

/// Represents the origin from which a search is initiated.
enum SearchOrigin {
    /// Search initiated from the Discover tab
    case discover
    
    /// Search initiated from ``AuthorListManageUsersView``
    case lists

    /// Search initiated from the mentions `AuthorSearchView`
    case mentions
}

/// Manages a search query and list of results.
@Observable final class SearchController {
    
    // MARK: - Properties
    
    /// The search query string.
    var query: String = "" {
        didSet {
            queryPublisher.send(query)
        }
    }
    @ObservationIgnored private lazy var queryPublisher = CurrentValueSubject<String, Never>(query)
    
    /// Any and all authors in the search results. As of this writing, _only_ authors appear in search results,
    /// so this contains all search results, period.
    private(set) var authorResults = [Author]()

    private(set) var state: SearchState = .noQuery

    @ObservationIgnored @Dependency(\.router) private var router
    @ObservationIgnored @Dependency(\.relayService) private var relayService
    @ObservationIgnored @Dependency(\.persistenceController) private var persistenceController
    @ObservationIgnored @Dependency(\.currentUser) private var currentUser
    @ObservationIgnored @Dependency(\.analytics) private var analytics

    private var cancellables = [AnyCancellable]()
    private var searchSubscriptions = SubscriptionCancellables()

    /// The timer for showing the "not finding results" view. Resets any time the query is changed.
    private var timer: Timer?

    @ObservationIgnored private lazy var context = persistenceController.viewContext

    /// The amount of time, in seconds, to remain in the `.loading` state until switching to `.stillLoading`.
    private let stillLoadingTime: TimeInterval = 10

    /// The origin of the current search.
    private let searchOrigin: SearchOrigin
    
    /// If true, will automatically trigger routing to detail views for exact matches of NIP-05s, npubs, and note ids.
    private let routesMatchesAutomatically: Bool

    // MARK: - Init
    
    init(searchOrigin: SearchOrigin = .discover, routesMatchesAutomatically: Bool = true) {
        self.searchOrigin = searchOrigin
        self.routesMatchesAutomatically = routesMatchesAutomatically

        queryPublisher
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
                if self.state == .noQuery {
                    // User is starting a new search
                    switch searchOrigin {
                    case .discover:
                        analytics.searchedDiscover()
                    case .lists:
                        break // TODO: Analytics
                    case .mentions:
                        analytics.mentionsAutocompleteCharactersEntered()
                    }
                }
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

        observeContextChanges()
    }

    /// Observes changes in the `NSManagedObjectContext` and updates the query and author results.
    private func observeContextChanges() {
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
    
    private func author(fromPublicKey publicKeyString: String) -> Author? {
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
    
    private func authors(named name: String) -> [Author] {
        guard let authors = try? Author.find(named: name, context: context) else {
            return []
        }
        return authors.sorted(by: { $0.followers.count > $1.followers.count })
    }
    
    private func clear() {
        state = .noQuery
        searchSubscriptions.removeAll()
        timer?.invalidate()
        query = ""
        authorResults = []
    }
    
    private func note(fromPublicKey publicKeyString: String) -> Event? {
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
    
    /// Searches the relays for the given query.
    /// - Parameter query: The string to search for.
    ///
    /// - Warning: SIDE EFFECT WARNING:
    /// These functions search other systems for the given query and add relevant authors to the database.
    /// The database then generates a notification which is listened to above and results are reloaded.
    private func search(for query: String) {
        // if there are no results, go into the `loading` state (which will show the spinner)
        // otherwise, keep showing the results
        if state != .results {
            state = .loading
        }
        startSearchTimer()
        Task {
            self.searchSubscriptions.removeAll()
            self.searchRelays(for: query)
        }
    }

    private func searchRelays(for query: String) {
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
    
    private func startSearchTimer() {
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
    /// Finally, if all previous checks fail, searches the relays for the given query.
    func submitSearch(query: String) {
        searchSubscriptions.removeAll()

        let trimmedQuery = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedQuery.contains("@") {
            Task(priority: .userInitiated) {
                if let publicKeyHex = await relayService.retrievePublicKeyFromUsername(trimmedQuery) {
                    Task { @MainActor in
                        if let author = try? Author.findOrCreate(by: publicKeyHex, context: context) {
                            if routesMatchesAutomatically {
                                analytics.displayedAuthorFromDiscoverSearch(resultsCount: 1)
                                router.push(author)
                            } else {
                                authorResults = [author]
                            }
                        }
                    }
                }
            }
        } else if let author = author(fromPublicKey: trimmedQuery) {
            Task { @MainActor in
                if routesMatchesAutomatically {
                    analytics.displayedAuthorFromDiscoverSearch(resultsCount: 1)
                    router.push(author)
                } else {
                    authorResults = [author]
                }
            }
        } else if routesMatchesAutomatically, let note = note(fromPublicKey: trimmedQuery) {
            Task { @MainActor in
                analytics.displayedNoteFromDiscoverSearch()
                router.push(note)
            }
        } else {
            search(for: trimmedQuery)
        }
    }
}
