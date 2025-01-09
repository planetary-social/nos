import SwiftUI
import CoreData
import Combine
import Dependencies
import TipKit
import Inject

struct HomeFeedView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var router: Router
    @ObservationIgnored @Dependency(\.analytics) private var analytics
    @ObserveInjection var inject

    @State private var refreshController = RefreshController(lastRefreshDate: Date.now + Self.staticLoadTime)
    @State private var isVisible = false
    @State private var feedController: FeedController
    
    /// When set to true this will display a fullscreen progress wheel for a set amount of time to give us a chance
    /// to get some data from relay. The amount of time is defined in `staticLoadTime`.
    @State private var showTimedLoadingIndicator = true
    
    @State private var shouldNavigateToRelaysOnAppear = false
    
    /// The amount of time (in seconds) the loading indicator will be shown when showTimedLoadingIndicator is set to 
    /// true.
    private static let staticLoadTime: TimeInterval = 2
    
    private let stackSpacing: CGFloat = 8

    let user: Author
    @Binding var showFeedTip: Bool
    @Binding var scrollOffsetY: CGFloat
    
    init(user: Author, showFeedTip: Binding<Bool>, scrollOffsetY: Binding<CGFloat>) {
        self.user = user
        self._showFeedTip = showFeedTip
        self._scrollOffsetY = scrollOffsetY
        _feedController = State(initialValue: FeedController(author: user))
    }
    
    /// A tip to display at the top of the feed.
    private let welcomeTip = WelcomeToFeedTip()

    @State private var showFeedSelector = false
    
    private var homeFeedFetchRequest: NSFetchRequest<Event> {
        Event.homeFeed(
            for: user,
            before: refreshController.lastRefreshDate,
            seenOn: feedController.selectedRelay,
            from: feedController.selectedList?.allAuthors
        )
    }

    private var newNotesRequest: NSFetchRequest<Event> {
        Event.homeFeed(
            for: user,
            after: refreshController.lastRefreshDate,
            seenOn: feedController.selectedRelay,
            from: feedController.selectedList?.allAuthors
        )
    }

    private var homeFeedFilter: Filter {
        var filter = Filter(kinds: [.text, .delete, .repost, .longFormContent, .report])
        if feedController.selectedRelay == nil {
            if let list = feedController.selectedList {
                filter.authorKeys = list.allAuthors.compactMap { $0.hexadecimalPublicKey }.filter { $0.isValid }
            } else {
                filter.authorKeys = user.followedKeys.sorted()
            }
        }
        return filter
    }

    var body: some View {
        ZStack {
            VStack(spacing: stackSpacing) {
                FeedPicker()
                    .padding(.bottom, -stackSpacing)    // remove the padding below the picker
                
                TipView(welcomeTip)
                    .padding(.top, 20)
                    .padding(.horizontal, 16)
                    .readabilityPadding()
                    .tipBackground(LinearGradient.horizontalAccentReversed)
                    .tipViewStyle(.inline)

                PagedNoteListView(
                    refreshController: $refreshController,
                    scrollOffsetY: $scrollOffsetY,
                    databaseFilter: homeFeedFetchRequest,
                    relayFilter: homeFeedFilter,
                    relay: feedController.selectedRelay,
                    managedObjectContext: viewContext,
                    tab: .home,
                    header: {
                        EmptyView()
                    },
                    emptyPlaceholder: {
                        VStack {
                            Text("noEvents")
                                .padding()
                        }
                        .frame(minHeight: 300)
                    }
                )
                .padding(0)
            }

            NewNotesButton(fetchRequest: FetchRequest(fetchRequest: newNotesRequest)) {
                refreshController.startRefresh = true
            }
            .padding(.top, 44)

            if showTimedLoadingIndicator {
                FullscreenProgressView(
                    isPresented: $showTimedLoadingIndicator,
                    hideAfter: .now() + .seconds(Int(Self.staticLoadTime))
                )
            } 
            
            if showFeedSelector {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showFeedSelector = false
                        }
                    }
                    .transition(.opacity)
                
                VStack {
                    FeedCustomizerView(author: user, shouldNavigateToRelays: $shouldNavigateToRelaysOnAppear)
                    Spacer()
                }
                .transition(.move(edge: .top))
                .zIndex(99) // Fixes dismissal animation
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
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                SideMenuButton()
            }
            ToolbarItem(placement: .principal) {
                Image.nosLogo
                    .resizable()
                    .scaledToFit()
                    .frame(height: 20)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    withAnimation {
                        showFeedSelector.toggle()
                        showFeedTip = false
                    }
                } label: {
                    Image(systemName: showFeedSelector ? "xmark.circle.fill" : "line.3.horizontal.decrease.circle")
                        .foregroundStyle(Color.secondaryTxt)
                        .accessibilityLabel("filter")
                }
                .frame(minWidth: 40, minHeight: 40)
            }
        }
        .animation(.easeOut, value: showFeedSelector)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.cardBgBottom, for: .navigationBar)
        .navigationBarTitle("", displayMode: .inline)
        .padding(.top, 1)
        .environment(feedController)
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
        .onChange(of: shouldNavigateToRelaysOnAppear) {
            if shouldNavigateToRelaysOnAppear {
                showFeedSelector = false
                
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) {
                    router.push(RelaysDestination(author: user, relays: []))
                }
                
                shouldNavigateToRelaysOnAppear = false
            }
        }
        .navigationDestination(for: RelaysDestination.self) { destination in
            RelayView(author: destination.author)
        }
        .enableInjection()
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
        
        _ = previewData.shortNote
    }
    
    return NavigationStack {
        HomeFeedView(user: previewData.alice, showFeedTip: .constant(false), scrollOffsetY: .constant(0))
    }
    .inject(previewData: previewData)
    .onAppear {
        createTestData()
    }
}
