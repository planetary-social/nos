import Combine
import CoreData
import Dependencies
import SwiftUI

/// The source to be used for a feed of notes.
enum FeedSource: RawRepresentable, Hashable, Equatable {
    case following
    case relay(String, String?)
    case list(String, String?)
    
    var displayName: String {
        switch self {
        case .following: String(localized: "following")
        case .relay(let name, _), .list(let name, _): name
        }
    }
    
    var description: String? {
        switch self {
        case .following: nil
        case .relay(_, let description), .list(_, let description): description
        }
    }
    
    static func == (lhs: FeedSource, rhs: FeedSource) -> Bool {
        switch (lhs, rhs) {
        case (.following, .following): true
        case (.relay(let name1, _), .relay(let name2, _)): name1 == name2
        case (.list(let name1, _), .list(let name2, _)): name1 == name2
        default: false
        }
    }
    
    // Note: RawRepresentable conformance is required for use of @AppStorage for persistence.
    var rawValue: String {
        switch self {
        case .following:
            "following"
        case .relay(let host, let description):
            "relay:|\(host):|\(description ?? "")"
        case .list(let name, let description):
            "list:|\(name):|\(description ?? "")"
        }
    }
    
    init?(rawValue: String) {
        let components = rawValue.split(separator: ":|").map { String($0) }
        guard let caseName = components.first else {
            return nil
        }
        
        switch caseName {
        case "following":
            self = .following
        case "relay":
            guard components.count >= 2 else {
                return nil
            }
            let description = components.count >= 3 ? components[2] : ""
            self = .relay(components[1], description)
        case "list":
            guard components.count >= 2 else {
                return nil
            }
            let description = components.count >= 3 ? components[2] : ""
            self = .list(components[1], description)
        default:
            return nil
        }
    }
}

@Observable @MainActor final class FeedController {
    
    @ObservationIgnored @Dependency(\.persistenceController) private var persistenceController
    
    let author: Author
    
    var enabledSources: [FeedSource] = [.following]
    
    private(set) var selectedList: AuthorList?
    private(set) var selectedRelay: Relay?
    
    @ObservationIgnored @AppStorage("selectedFeedSource") private var persistedSelectedSource = FeedSource.following
    
    var selectedSource = FeedSource.following {
        didSet {
            updateSelectedListOrRelay()
            persistedSelectedSource = selectedSource
        }
    }
    
    private(set) var listRowItems: [FeedToggleRow.Item] = []
    private(set) var relayRowItems: [FeedToggleRow.Item] = []
    
    private var lists: [AuthorList] = [] {
        didSet {
            updateEnabledSources()
        }
    }
    private var relays: [Relay] = [] {
        didSet {
            updateEnabledSources()
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    init(author: Author) {
        self.author = author
        observeLists()
        observeRelays()
        
        // The delay here is an unfortunate workaround. Without it, the feed always resumes to
        // the default value of FeedSource.following.
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
            self.selectedSource = self.persistedSelectedSource
        }
    }
    
    private func observeLists() {
        let request = NSFetchRequest<AuthorList>(entityName: "AuthorList")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Event.createdAt, ascending: false)]
        request.predicate = NSPredicate(
            format: "kind = %i AND author = %@ AND title != nil",
            EventKind.followSet.rawValue,
            author
        )
        
        let listWatcher = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: persistenceController.viewContext,
            sectionNameKeyPath: nil,
            cacheName: "FeedController.listWatcher"
        )
        
        FetchedResultsControllerPublisher(fetchedResultsController: listWatcher)
            .publisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] lists in
                self?.lists = lists
            })
            .store(in: &cancellables)
    }
    
    private func observeRelays() {
        let request = Relay.relays(for: author)
        
        let relayWatcher = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: persistenceController.viewContext,
            sectionNameKeyPath: nil,
            cacheName: "FeedController.relayWatcher"
        )
        
        FetchedResultsControllerPublisher(fetchedResultsController: relayWatcher)
            .publisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] relays in
                self?.relays = relays
            })
            .store(in: &cancellables)
    }
    
    private func updateSelectedListOrRelay() {
        switch selectedSource {
        case .relay(let address, _):
            if let relay = relays.first(where: { $0.host == address }) {
                selectedRelay = relay
                selectedList = nil
            }
        case .list(let title, _):
            // TODO: Needs to use replaceableID instead of title
            if let list = lists.first(where: { $0.title == title }) {
                selectedList = list
                selectedRelay = nil
            }
        default:
            selectedList = nil
            selectedRelay = nil
        }
    }
    
    private func updateEnabledSources() {
        var enabledSources = [FeedSource]()
        enabledSources.append(.following)
        
        var listItems = [FeedToggleRow.Item]()
        var relayItems = [FeedToggleRow.Item]()
        
        for list in lists {
            let source = FeedSource.list(list.title ?? "??", nil)
            
            if list.isFeedEnabled {
                enabledSources.append(source)
            }
            
            listItems.append(FeedToggleRow.Item(source: source, isOn: list.isFeedEnabled))
        }
        
        for relay in relays {
            let source = FeedSource.relay(relay.host ?? "", relay.relayDescription)
            
            if relay.isFeedEnabled {
                enabledSources.append(source)
            }
            
            relayItems.append(FeedToggleRow.Item(source: source, isOn: relay.isFeedEnabled))
        }
        
        self.enabledSources = enabledSources
        self.listRowItems = listItems
        self.relayRowItems = relayItems
    }
    
    func toggleSourceEnabled(_ source: FeedSource) {
        do {
            switch source {
            case .relay(let address, _):
                if let relay = relays.first(where: { $0.host == address }) {
                    relay.isFeedEnabled.toggle()
                    try relay.managedObjectContext?.save()
                    updateEnabledSources()
                }
            case .list(let title, _):
                // TODO: Needs to use replaceableID instead of title
                if let list = lists.first(where: { $0.title == title }) {
                    list.isFeedEnabled.toggle()
                    try list.managedObjectContext?.save()
                    updateEnabledSources()
                }
            default:
                break
            }
        } catch {
            print("FeedController: error updating source: \(source), error: \(error)")
        }
    }
    
    func isSourceEnabled(_ source: FeedSource) -> Bool {
        enabledSources.contains(source)
    }
}
