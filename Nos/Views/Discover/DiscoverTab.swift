import SwiftUI
import Combine
import CoreData
import Dependencies
import TipKit

struct PopoverTip: Tip {
    // Define the app state you want to track.
    @Parameter
    static var isToggle: Bool = false

    var title: Text {
        Text("How is Discover populated?")
            .font(.callout)
            .bold()
//            .foregroundStyle(Color.secondaryTxt)
    }

    var message: Text? {
        Text("Accounts on this tab are participants in the Nos Residency and Accelerator programs.")
            .font(.footnote)
//            .foregroundStyle(Color.secondaryTxt)
    }

    var rules: [Rule] {
        #Rule(Self.$isToggle) { $0 == true }
    }

    var options: [TipOption] {
        [
            Tip.IgnoresDisplayFrequency(true),
            Tip.MaxDisplayCount(.max)
        ]
    }
}

struct DiscoverTab: View {    
    // MARK: - Properties
    
    @EnvironmentObject private var relayService: RelayService
    @EnvironmentObject private var router: Router
    @Environment(CurrentUser.self) var currentUser
    @Dependency(\.analytics) private var analytics

    @State var showInfoPopover = false
    var popoverTip = PopoverTip()

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
                    VStack {
                        TipView(popoverTip)
                            .padding()
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
            .toolbar {
                ToolbarItem {
                    Button {
                        // TODO: actually show the popover. https://github.com/planetary-social/nos/issues/1025
                        showInfoPopover = true
                        PopoverTip.isToggle = true
                    } label: {
                        Image.discoverInfo
                    }
                    .foregroundStyle(Color.secondaryTxt)
                    .onChange(of: showInfoPopover) { _, _ in
                        withAnimation {
                            showInfoPopover.toggle()
                            // here we can manipulate the state to satisfy a condition to show the tip.
                            PopoverTip.isToggle = showInfoPopover
                        }
                    }
//                    .popoverTip(popoverTip)
                }
            }
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
            _ = try? Relay(context: previewContext, address: $0, author: user)
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
