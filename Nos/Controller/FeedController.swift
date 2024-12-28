import Combine
import CoreData
import Dependencies
import SwiftUI

/// The source to be used for a feed of notes.
enum FeedSource: Hashable, Equatable {
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
}

@Observable @MainActor final class FeedController {
    
    @ObservationIgnored @Dependency(\.persistenceController) private var persistenceController
    @ObservationIgnored @Dependency(\.currentUser) private var currentUser
    
    var enabledSources: [FeedSource] = [.following]
    
    private(set) var selectedList: AuthorList?
    private(set) var selectedRelay: Relay?
    var selectedSource: FeedSource = .following {
        didSet {
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
    
    init() {
        observeLists()
        observeRelays()
    }
    
    private func observeLists() {
        guard let author = currentUser.author else {
            return
        }
        
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
        guard let author = currentUser.author else {
            return
        }
        
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
