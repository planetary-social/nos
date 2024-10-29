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

struct HorizontalStreamCarousel: View {
    
    var streamName: String 
    
    @FetchRequest var streamPhotos: FetchedResults<Event>
    
    init(streamName: String) {
        self.streamName = streamName
        _streamPhotos = FetchRequest(fetchRequest: Event.by(hashtag: streamName))
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(streamName)
                    .font(.title)
                Spacer()
            }
            .padding(.top)
            
            if let authorName = streamPhotos.last?.author?.safeName {
                HStack {
                    Text("by ") + Text(authorName).underline()
                    Spacer()
                }
                .font(.callout)
            }
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(streamPhotos) { photoEvent in
                        VStack {
                            if !photoEvent.contentLinks.isEmpty {
                                GalleryView(
                                    urls: Array(photoEvent.contentLinks.prefix(1)),
                                    metadata: photoEvent.inlineMetadata
                                )
                                .cornerRadius(3)
                            }
                        }
                        .task { await photoEvent.loadAttributedContent() }
                    }
                }
                .frame(height: 200)
            }
        }
        .padding()
    }
}
