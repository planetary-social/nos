import SwiftUI
import Combine
import CoreData
import Dependencies

struct DiscoverTab: View {    
    // MARK: - Properties
    
    @EnvironmentObject private var relayService: RelayService
    @EnvironmentObject private var router: Router
    @Environment(CurrentUser.self) var currentUser
    @Dependency(\.analytics) private var analytics

    @State var showInfoPopover = false

    @State var columns: Int = 0
    
    @State private var performingInitialLoad = true
    static let initialLoadTime = 2
    @State private var isVisible = false

    @StateObject private var searchController = SearchController()
    @State private var date = Date(timeIntervalSince1970: Date.now.timeIntervalSince1970 + Double(Self.initialLoadTime))

    @State var predicate: NSPredicate = .false

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
                    FeaturedAuthorsView(
                        featuredAuthorCategory: .all,
                        searchController: searchController
                    )
                }
            }
            .searchable(
                text: $searchController.query, 
                placement: .toolbar, 
                prompt: Text(.localizable.searchBar)
            )
            .autocorrectionDisabled()
            .onSubmit(of: .search) {
                searchController.submitSearch(query: searchController.query)
            }
            .background(Color.appBg)
            .animation(.easeInOut, value: columns)
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
            .navigationDestination(for: EditProfileDestination.self) { destination in
                ProfileEditView(author: destination.profile)
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

struct DiscoverTab_Previews: PreviewProvider {
    
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
            let relay = try? Relay.findOrCreate(by: $0, context: previewContext)
            relay?.addToAuthors(user)
        }

        try? previewContext.save()
    }
    
    @State static var relayFilter: Relay?
    
    static var previews: some View {
        DiscoverTab()
            .environment(\.managedObjectContext, previewContext)
            .environmentObject(relayService)
            .environmentObject(router)
            .environment(currentUser)
            .onAppear { createTestData(in: previewContext) }
        
        DiscoverTab()
            .environment(\.managedObjectContext, previewContext)
            .environmentObject(relayService)
            .environmentObject(router)
            .environment(currentUser)
            .onAppear { createTestData(in: previewContext) }
            .previewDevice("iPad Air (5th generation)")
    }
}
