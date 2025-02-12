import Combine
import CoreData
import Dependencies
import SwiftUI

@Observable @MainActor final class FeedController {
    
    @ObservationIgnored @Dependency(\.persistenceController) private var persistenceController
    
    let author: Author
    
    private(set) var enabledSources: [FeedSource] = [.following]
    
    private(set) var selectedList: AuthorList?
    private(set) var selectedRelay: Relay?
    
    @ObservationIgnored @AppStorage("selectedFeedSource") private var persistedSelectedSource = FeedSource.following
    private var hasSetInitialSelectedSource: Bool = false
    
    var selectedSource = FeedSource.following {
        didSet {
            updateSelectedListOrRelay()
            persistedSelectedSource = selectedSource
        }
    }
    
    private(set) var listRowItems: [FeedToggleRow.Item] = []
    private(set) var relayRowItems: [FeedToggleRow.Item] = []
    
    private(set) var lists: [AuthorList] = [] {
        didSet {
            updateEnabledSources()
        }
    }
    private var relays: [Relay] = [] {
        didSet {
            updateEnabledSources()
        }
    }
    
    @ObservationIgnored private lazy var listsPublisher = {
        let listWatcher = NSFetchedResultsController(
            fetchRequest: AuthorList.authorLists(ownedBy: author),
            managedObjectContext: persistenceController.viewContext,
            sectionNameKeyPath: nil,
            cacheName: "FeedController.listWatcher"
        )
        
        return FetchedResultsControllerPublisher(fetchedResultsController: listWatcher)
    }()
    
    @ObservationIgnored private lazy var relaysPublisher = {
        let request = Relay.relays(for: author)
        
        let relayWatcher = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: persistenceController.viewContext,
            sectionNameKeyPath: nil,
            cacheName: "FeedController.relayWatcher"
        )
        
        return FetchedResultsControllerPublisher(fetchedResultsController: relayWatcher)
    }()
    
    private var cancellables = Set<AnyCancellable>()
    
    init(author: Author) {
        self.author = author
        observeLists()
        observeRelays()
    }
    
    private func observeLists() {
        listsPublisher
            .publisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] lists in
                guard let self else {
                    return
                }
                
                self.lists = lists
                
                if case .list = self.persistedSelectedSource, !self.hasSetInitialSelectedSource {
                    selectedSource = persistedSelectedSource
                    self.hasSetInitialSelectedSource = true
                }
            })
            .store(in: &cancellables)
    }
    
    private func observeRelays() {
        relaysPublisher
            .publisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] relays in
                guard let self else {
                    return
                }
                
                self.relays = relays
                
                if case .relay = self.persistedSelectedSource, !self.hasSetInitialSelectedSource {
                    selectedSource = persistedSelectedSource
                    self.hasSetInitialSelectedSource = true
                }
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
            let source = FeedSource.list(name: list.title ?? "??", description: nil)
            
            if list.isFeedEnabled {
                enabledSources.append(source)
            }
            
            listItems.append(FeedToggleRow.Item(source: source, isOn: list.isFeedEnabled))
        }
        
        for relay in relays {
            let source = FeedSource.relay(host: relay.host ?? "", description: relay.relayDescription)
            
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
