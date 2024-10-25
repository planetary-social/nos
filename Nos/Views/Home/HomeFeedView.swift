import SwiftUI
import CoreData
import Combine
import Dependencies
import TipKit

struct HomeFeedView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var router: Router
    @ObservationIgnored @Dependency(\.analytics) private var analytics

    @State private var refreshController = RefreshController(lastRefreshDate: Date.now + Self.staticLoadTime)
    @State private var isVisible = false
    
    /// When set to true this will display a fullscreen progress wheel for a set amount of time to give us a chance
    /// to get some data from relay. The amount of time is defined in `staticLoadTime`.
    @State private var showTimedLoadingIndicator = true
    
    /// The amount of time (in seconds) the loading indicator will be shown when showTimedLoadingIndicator is set to 
    /// true.
    static let staticLoadTime: TimeInterval = 2

    let user: Author
    
    /// A tip to display at the top of the feed.
    let welcomeTip = WelcomeToFeedTip()

    @State private var showRelayPicker = false
    @State private var selectedRelay: Relay? 
    
    @FetchRequest<Event>(
        entity: Event.entity(), 
        sortDescriptors: [NSSortDescriptor(keyPath: \Event.createdAt, ascending: true)]
    ) private var notes

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
        var filter = Filter(kinds: [.text, .delete, .repost, .longFormContent, .report])
        if selectedRelay == nil {
            filter.authorKeys = user.followedKeys.sorted()
        } 
        return filter
    }
    
    var navigationBarTitle: LocalizedStringKey {
        "Latest"
    }

    var body: some View {
        ZStack {
            VStack(spacing: 8) {
                ScrollView {
                    ForEach(notes) { note in
                        VStack {
                            if !note.contentLinks.isEmpty {
                                GalleryView(urls: note.contentLinks, metadata: note.inlineMetadata)
                            }
                        }
                        .task { await note.loadAttributedContent() }
                    }
                }
            }

            NewNotesButton(fetchRequest: FetchRequest(fetchRequest: newNotesRequest)) {
                refreshController.startRefresh = true
            }

            if showTimedLoadingIndicator {
                FullscreenProgressView(
                    isPresented: $showTimedLoadingIndicator,
                    hideAfter: .now() + .seconds(Int(Self.staticLoadTime))
                )
            } 
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
        .onAppear {
            if router.selectedTab == .home {
                isVisible = true
            }
        }
        .onDisappear { isVisible = false }
        .onChange(of: isVisible) { 
            if isVisible {
                analytics.showedHome()
                GoToFeedTip.viewedFeed.sendDonation()
            }
        }
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
