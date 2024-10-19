import SwiftUI
import Combine
import CoreData
import Dependencies
import TipKit

struct DiscoverTab: View {
    // MARK: - Properties
    
    @EnvironmentObject private var router: Router
    @Environment(CurrentUser.self) var currentUser
    @Dependency(\.analytics) private var analytics

    @State var showInfoPopover = false

    @State var columns: Int = 0
    
    @State private var isVisible = false

    @State private var searchController = SearchController()

    @State var predicate: NSPredicate = .false

    let goToFeedTip = GoToFeedTip()

    // MARK: - View
    
    var body: some View {
        NosNavigationStack(path: $router.discoverPath) {
            ZStack {
                DiscoverContentsView(
                    featuredAuthorCategory: .all,
                    searchController: searchController
                )

                VStack {
                    Spacer()
                    
                    TipView(goToFeedTip)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)
                        .readabilityPadding()
                        .tipBackground(LinearGradient.horizontalAccentReversed)
                        .tipViewStyle(.pointDownEmoji)
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
            .nosNavigationBar(title: .localizable.discover)
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
    static var previewContext = persistenceController.viewContext

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

    static var previews: some View {
        DiscoverTab()
            .environment(\.managedObjectContext, previewContext)
            .environmentObject(router)
            .environment(currentUser)
            .onAppear { createTestData(in: previewContext) }
        
        DiscoverTab()
            .environment(\.managedObjectContext, previewContext)
            .environmentObject(router)
            .environment(currentUser)
            .onAppear { createTestData(in: previewContext) }
            .previewDevice("iPad Air (5th generation)")
    }
}
