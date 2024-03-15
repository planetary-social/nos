import SwiftUI
import Combine
import CoreData
import Dependencies

struct DiscoverView: View {    
    // MARK: - Properties
    
    @EnvironmentObject private var relayService: RelayService
    @EnvironmentObject private var router: Router
    @Environment(CurrentUser.self) var currentUser
    @Dependency(\.analytics) private var analytics

    @State var showRelayPicker = false
    
    @State var relayFilter: Relay?
    
    @State var columns: Int = 0
    
    @State private var performingInitialLoad = true
    static let initialLoadTime = 2
    @State private var relaySubscriptions = SubscriptionCancellables()
    @State private var isVisible = false
    private var featuredAuthors: [String]
    
    @StateObject private var searchController = SearchController()
    @State private var date = Date(timeIntervalSince1970: Date.now.timeIntervalSince1970 + Double(Self.initialLoadTime))

    @State var predicate: NSPredicate = .false

    // MARK: - Init
    
    init(featuredAuthors: [String] = Array(Event.discoverTabUserIdToInfo.keys)) {
        self.featuredAuthors = featuredAuthors
    }

    // MARK: - Internal
    
    func cancelSubscriptions() async {
        relaySubscriptions.removeAll()
    }
    
    func subscribeToNewEvents() async {
        await cancelSubscriptions()
        
        if let relayAddress = relayFilter?.addressURL {
            // TODO: Use a since filter
            let singleRelayFilter = Filter(
                kinds: [.text, .delete],
                limit: 200
            )
            
            relaySubscriptions.append(
                await relayService.subscribeToEvents(matching: singleRelayFilter, from: [relayAddress])
            )
        } else {
            let featuredFilter = Filter(
                authorKeys: featuredAuthors.compactMap {
                    PublicKey(npub: $0)?.hex
                },
                kinds: [.text, .delete],
                limit: 200
            )
            
            relaySubscriptions.append(await relayService.subscribeToEvents(matching: featuredFilter))
        }
    }
    
    func updatePredicate() {
        if let relayFilter {
            predicate = Event.seen(on: relayFilter, before: date, exceptFrom: currentUser.author)
        } else {
            predicate = Event.extendedNetworkPredicate(
                currentUser: currentUser,
                featuredAuthors: featuredAuthors,
                before: date
            )
        }
    }
    
    // MARK: - View
    
    var body: some View {
        NavigationStack(path: $router.discoverPath) {
            ZStack {
                if performingInitialLoad && searchController.query.isEmpty {
                    FullscreenProgressView(
                        isPresented: $performingInitialLoad, 
                        hideAfter: .now() + .seconds(Self.initialLoadTime)
                    )
                } else {
                    DiscoverGrid(predicate: predicate, searchController: searchController, columns: $columns)
                    
                    if showRelayPicker, let author = currentUser.author {
                        RelayPicker(
                            selectedRelay: $relayFilter,
                            defaultSelection: String(localized: .localizable.allMyRelays),
                            author: author,
                            isPresented: $showRelayPicker
                        )
                    }
                }
            }
            .searchable(
                text: $searchController.query, 
                placement: .toolbar, 
                prompt: PlainText(.localizable.searchBar)
            )
            .autocorrectionDisabled()
            .onSubmit(of: .search) {
                searchController.submitSearch(query: searchController.query)
            }
            .background(Color.appBg)
            .toolbar {
                RelayPickerToolbarButton(
                    selectedRelay: $relayFilter,
                    isPresenting: $showRelayPicker,
                    defaultSelection: .localizable.allMyRelays
                ) {
                    withAnimation {
                        showRelayPicker.toggle()
                    }
                }
                ToolbarItem {
                    HStack {
                        Button {
                            columns = max(columns - 1, 1)
                        } label: {
                            Image(systemName: "minus")
                        }
                        Button {
                            columns += 1
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .animation(.easeInOut, value: columns)
            .task { 
                updatePredicate()
            }
            .refreshable {
                date = .now
            }
            .onChange(of: relayFilter) { 
                withAnimation {
                    showRelayPicker = false
                }
                updatePredicate()
                Task { await subscribeToNewEvents() }
            }
            .onChange(of: date) { 
                updatePredicate()
            }
            .refreshable {
                date = .now
            }
            .onAppear {
                if router.selectedTab == .discover {
                    isVisible = true
                }
            }
            .onDisappear {
                isVisible = false
            }
            .onChange(of: isVisible) { 
                if isVisible {
                    analytics.showedDiscover()
                    Task { await subscribeToNewEvents() }
                } else {
                    Task { await cancelSubscriptions() }
                }
            }
            .navigationDestination(for: Event.self) { note in
                RepliesView(note: note)
            }
            .navigationDestination(for: URL.self) { url in URLView(url: url) }
            .navigationDestination(for: ReplyToNavigationDestination.self) { destination in 
                RepliesView(note: destination.note, showKeyboard: true)
            }
            .navigationDestination(for: Author.self) { author in
                ProfileView(author: author)
            }
            .navigationBarTitle(String(localized: .localizable.discover), displayMode: .inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.cardBgBottom, for: .navigationBar)
            .navigationBarItems(leading: SideMenuButton())
        }
    }
}

struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

struct DiscoverView_Previews: PreviewProvider {
    
    static var previewData = PreviewData()
    static var persistenceController = PersistenceController.preview
    static var previewContext = persistenceController.container.viewContext
    static var relayService = previewData.relayService
    
    static var emptyPersistenceController = PersistenceController.empty
    static var emptyPreviewContext = emptyPersistenceController.container.viewContext
    static var emptyRelayService = previewData.relayService
    static var currentUser = previewData.currentUser
    static var router = Router()
    
    static var user: Author {
        let author = Author(context: previewContext)
        author.hexadecimalPublicKey = KeyFixture.alice.publicKeyHex
        return author
    }
    
    static func createTestData(in context: NSManagedObjectContext) {
        let shortNote = Event(context: previewContext)
        shortNote.identifier = "1"
        shortNote.author = user
        shortNote.content = "Hello, world!"
        
        let longNote = Event(context: previewContext)
        longNote.identifier = "2"
        longNote.author = user
        longNote.content = .loremIpsum(5)

        try? previewContext.save()
    }
    
    static func createRelayData(in context: NSManagedObjectContext, user: Author) {
        let addresses = ["wss://nostr.band", "wss://nos.social", "wss://a.long.domain.name.to.see.what.happens"]
        addresses.forEach {
            _ = try? Relay(context: previewContext, address: $0, author: user)
        }

        try? previewContext.save()
    }
    
    @State static var relayFilter: Relay?
    
    static var previews: some View {
        if let publicKey = user.publicKey {
            DiscoverView(featuredAuthors: [publicKey.npub])
                .environment(\.managedObjectContext, previewContext)
                .environmentObject(relayService)
                .environmentObject(router)
                .environment(currentUser)
                .onAppear { createTestData(in: previewContext) }

            DiscoverView(featuredAuthors: [publicKey.npub])
                .environment(\.managedObjectContext, previewContext)
                .environmentObject(relayService)
                .environmentObject(router)
                .environment(currentUser)
                .onAppear { createTestData(in: previewContext) }
                .previewDevice("iPad Air (5th generation)")
        } else {
            EmptyView()
        }
    }
}
