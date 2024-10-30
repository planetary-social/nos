import SwiftUI
import CoreData
import Combine
import Dependencies
import TipKit

struct HomeFeedView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var relayService: RelayService
    @EnvironmentObject private var router: Router
    @ObservationIgnored @Dependency(\.analytics) private var analytics

    @State private var refreshController = RefreshController(lastRefreshDate: Date.now)
    @State private var isVisible = false
    
    let user: Author
    
    /// A tip to display at the top of the feed.
    let welcomeTip = WelcomeToFeedTip()

    @State private var showRelayPicker = false
    @State private var selectedRelay: Relay? 
    @State private var cancellables = [SubscriptionCancellable]()
    
    @FetchRequest<Hashtag>(
        entity: Hashtag.entity(), 
        sortDescriptors: [NSSortDescriptor(keyPath: \Hashtag.name, ascending: true)]
    ) private var hashtags

    init(user: Author) {
        self.user = user
    }
    
    var homeFeedFetchRequest: NSFetchRequest<Event> {
        Event.homeFeed(
            for: user,
            before: refreshController.lastRefreshDate,
            seenOn: selectedRelay
        )
    }

    var newNotesRequest: NSFetchRequest<Event> {
        Event.homeFeed(
            for: user,
            after: refreshController.lastRefreshDate,
            seenOn: selectedRelay
        )
    }

    var homeFeedFilter: Filter {
        var filter = Filter(kinds: [.text])
        filter.authorKeys = user.followedKeys.sorted()
        filter.keepSubscriptionOpen = true
        return filter
    }
    
    var navigationBarTitle: LocalizedStringKey {
        "Latest"
    }

    var body: some View {
        ZStack {
            ScrollView(.vertical) {
                LazyVStack(spacing: 8) {
                    ForEach(hashtags) { hashtag in
                        HorizontalStreamCarousel(streamName: hashtag.name!)
                    }
                }
            }
        }
        .task {
            cancellables.removeAll()
            await cancellables.append(relayService.fetchEvents(matching: homeFeedFilter))
        }
        .doubleTapToPop(tab: .home) { _ in
            NotificationCenter.default.post(
                name: .scrollToTop,
                object: nil,
                userInfo: ["tab": AppDestination.home]
            )
        }
        .background(Color.appBg)
        .padding(.top, 1)
        .nosNavigationBar(navigationBarTitle)
        .navigationBarItems(leading: SideMenuButton())
        .onAppear {
            if router.selectedTab == .home {
                isVisible = true
            }
        }
        .onDisappear { isVisible = false }
    }
}

#Preview {
    var previewData = PreviewData()
    
    func createTestData() {
        let user = previewData.alice
        let addresses = Relay.recommended
        addresses.forEach { address in
            let relay = try? Relay.findOrCreate(by: address, context: previewData.previewContext)
            relay?.relayDescription = "A Nostr relay that aims to cultivate a healthy community."
            relay?.addToAuthors(user)
        }
        
        Task { try await previewData.currentUser.follow(author: previewData.bob) }
        
        _ = previewData.streamImageOne
        _ = previewData.streamImageTwo
        _ = previewData.streamImageThree
    }
    
    return NavigationStack {
        HomeFeedView(user: previewData.alice)
    }
    .inject(previewData: previewData)
    .onAppear {
        createTestData()
    }
}
