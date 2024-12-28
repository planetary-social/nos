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
    @State private var feedController = FeedController()
    
    /// When set to true this will display a fullscreen progress wheel for a set amount of time to give us a chance
    /// to get some data from relay. The amount of time is defined in `staticLoadTime`.
    @State private var showTimedLoadingIndicator = true
    
    @State private var shouldNavigateToRelaysOnAppear = false
    
    /// The amount of time (in seconds) the loading indicator will be shown when showTimedLoadingIndicator is set to 
    /// true.
    static let staticLoadTime: TimeInterval = 2
    
    private let stackSpacing: CGFloat = 8

    let user: Author
    
    /// A tip to display at the top of the feed.
    let welcomeTip = WelcomeToFeedTip()

    @State private var showRelayPicker = false
    @State private var selectedRelay: Relay?
    @State private var pickerSelected = FeedSource.following

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
        if let relayName = selectedRelay?.host {
            LocalizedStringKey(stringLiteral: relayName)
        } else {
            "accountsIFollow"
        }
    }

    var body: some View {
        ZStack {
            VStack(spacing: stackSpacing) {
                TipView(welcomeTip)
                    .padding(.top, 20)
                    .padding(.horizontal, 16)
                    .readabilityPadding()
                    .tipBackground(LinearGradient.horizontalAccentReversed)
                    .tipViewStyle(.inline)

                FeedPicker()
                    .padding(.bottom, -stackSpacing)    // remove the padding below the picker
                
                PagedNoteListView(
                    refreshController: $refreshController,
                    databaseFilter: homeFeedFetchRequest,
                    relayFilter: homeFeedFilter,
                    relay: selectedRelay,
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

            if showTimedLoadingIndicator {
                FullscreenProgressView(
                    isPresented: $showTimedLoadingIndicator,
                    hideAfter: .now() + .seconds(Int(Self.staticLoadTime))
                )
            } 
            
            if showRelayPicker {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        // Close on tap
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showRelayPicker = false
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
                        showRelayPicker.toggle()
                    }
                } label: {
                    Image(systemName: showRelayPicker ? "xmark.circle.fill" : "line.3.horizontal.decrease.circle")
                        .foregroundStyle(Color.secondaryTxt)
                        .accessibilityLabel("filter")
                }
                .frame(minWidth: 40, minHeight: 40)
            }
        }
        .animation(.easeOut, value: showRelayPicker)
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
                showRelayPicker = false
                
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) {
                    router.push(RelaysDestination(author: user, relays: []))
                }
                
                shouldNavigateToRelaysOnAppear = false
            }
        }
        .navigationDestination(for: RelaysDestination.self) { destination in
            RelayView(author: destination.author)
        }
    }
}

#Preview {
    @Previewable @State var previewData = PreviewData()
    
    func createTestData() {
        let user = previewData.alice
        let addresses = Relay.recommended
        addresses.forEach { address in
            let relay = try? Relay.findOrCreate(by: address, context: previewData.context)
            relay?.relayDescription = "A Nostr relay that aims to cultivate a healthy community."
            relay?.addToAuthors(user)
        }
        
        _ = previewData.shortNote
    }
    
    return NavigationStack {
        HomeFeedView(user: previewData.alice)
    }
    .inject(previewData: previewData)
    .onAppear {
        createTestData()
    }
}
