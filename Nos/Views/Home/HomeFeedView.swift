import SwiftUI
import CoreData
import Combine
import Dependencies

struct HomeFeedView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var relayService: RelayService
    @EnvironmentObject private var router: Router
    @Environment(CurrentUser.self) var currentUser
    @ObservationIgnored @Dependency(\.analytics) private var analytics

    @FetchRequest private var authors: FetchedResults<Author>
    
    @State private var lastRefreshDate = Date(
        timeIntervalSince1970: Date.now.timeIntervalSince1970 + Double(Self.staticLoadTime)
    )
    @State private var isVisible = false
    @State private var relaySubscriptions = [SubscriptionCancellable]()
    @State private var isShowingRelayList = false
    
    /// When set to true this will display a fullscreen progress wheel for a set amount of time to give us a chance
    /// to get some data from relay. The amount of time is defined in `staticLoadTime`.
    @State private var showTimedLoadingIndicator = true
    
    /// The amount of time (in seconds) the loading indicator will be shown when showTimedLoadingIndicator is set to 
    /// true.
    static let staticLoadTime: TimeInterval = 2

    let user: Author

    @State private var stories: [Author] = []
    @State private var selectedStoryAuthor: Author?
    @State private var storiesCutoffDate = Calendar.current.date(byAdding: .day, value: -2, to: .now)!
    
    @State private var showRelayPicker = false
    @State private var selectedRelay: Relay? 

    private var isShowingStories: Bool {
        selectedStoryAuthor != nil
    }
    
    init(user: Author) {
        self.user = user
        _authors = FetchRequest(
            fetchRequest: user.followedWithNewNotes(
                since: Calendar.current.date(byAdding: .day, value: -2, to: .now)!
            )
        )
    }
    
    var homeFeedFetchRequest: NSFetchRequest<Event> {
        Event.homeFeed(for: user, before: lastRefreshDate, seenOn: selectedRelay) 
    }
    
    var homeFeedFilter: Filter {
        var filter = Filter(kinds: [.text, .delete, .repost, .longFormContent, .report])
        if selectedRelay == nil {
            filter.authorKeys = user.followedKeys.sorted()
        } 
        return filter
    }
    
    var navigationBarTitle: LocalizedStringResource {
        if let relayName = selectedRelay?.host {
            LocalizedStringResource(stringLiteral: relayName)
        } else if isShowingStories {
            .localizable.stories
        } else {
            .localizable.accountsIFollow
        }
    }
    
    /// Downloads the data we need to show stories. 
    func downloadStories() async {
        relaySubscriptions.removeAll()
        
        let followedKeys = await Array(currentUser.socialGraph.followedKeys)
        
        if !followedKeys.isEmpty {
            let textFilter = Filter(
                authorKeys: followedKeys, 
                kinds: [.text, .delete, .repost, .longFormContent, .report], 
                since: storiesCutoffDate
            )
            let textSubs = await relayService.fetchEvents(matching: textFilter)
            relaySubscriptions.append(textSubs)
        }
    }
    
    var body: some View {
        ZStack {
            PagedNoteListView(
                databaseFilter: homeFeedFetchRequest,
                relayFilter: homeFeedFilter,
                relay: selectedRelay,
                context: viewContext,
                tab: .home,
                header: {
                    Group {
                        if selectedRelay == nil {
                            AuthorStoryCarousel(
                                authors: $stories, 
                                selectedStoryAuthor: $selectedStoryAuthor
                            )
                        } else {
                            EmptyView()
                        }
                    }
                },
                emptyPlaceholder: { _ in
                    VStack {
                        Text(.localizable.noEvents)
                            .padding()
                    }
                    .frame(minHeight: 300)
                },
                onRefresh: {
                    lastRefreshDate = .now
                    storiesCutoffDate = Calendar.current.date(byAdding: .day, value: -2, to: lastRefreshDate)!
                    authors.nsPredicate = user.followedWithNewNotesPredicate(
                        since: storiesCutoffDate
                    )
                    Task { await downloadStories() }
                    return Event.homeFeed(for: user, before: lastRefreshDate)
                }
            )
            .padding(0)
            
            StoriesView(
                cutoffDate: $storiesCutoffDate,
                authors: stories,
                selectedAuthor: $selectedStoryAuthor
            )
            .scaleEffect(isShowingStories ? 1 : 0.5)
            .opacity(isShowingStories ? 1 : 0)
            .animation(.default, value: selectedStoryAuthor)
            
            if showTimedLoadingIndicator {
                FullscreenProgressView(
                    isPresented: $showTimedLoadingIndicator,
                    hideAfter: .now() + .seconds(Int(Self.staticLoadTime))
                )
            } 
            
            if showRelayPicker {
                RelayPicker(
                    selectedRelay: $selectedRelay,
                    defaultSelection: String(localized: .localizable.accountsIFollow),
                    author: user,
                    isPresented: $showRelayPicker
                )
                .onChange(of: selectedRelay) { _, _ in
                    showTimedLoadingIndicator = true
                    lastRefreshDate = .now + Self.staticLoadTime
                    Task {
                        withAnimation {
                            showRelayPicker = false
                        }
                    }
                }
            }
        }
        .doubleTapToPop(tab: .home) { _ in
            if isShowingStories {
                selectedStoryAuthor = nil
            } else {
                NotificationCenter.default.post(
                    name: .scrollToTop,
                    object: nil,
                    userInfo: ["tab": AppDestination.home]
                )
            }
        }
        .background(Color.appBg)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                SideMenuButton()
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                if isShowingStories {
                    Button {
                        selectedStoryAuthor = nil
                    } label: {
                        Image.stories.rotationEffect(selectedStoryAuthor == nil ? Angle.zero : Angle(degrees: 90))
                            .animation(.default, value: selectedStoryAuthor)
                    }
                } else {
                    Button { 
                        withAnimation {
                            showRelayPicker.toggle()
                        }
                    } label: { 
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundStyle(Color.secondaryTxt)
                            .accessibilityLabel(Text(.localizable.filter))
                    }
                    .frame(minWidth: 40, minHeight: 40)
                }
            }
        }
        .padding(.top, 1)
        .nosNavigationBar(title: navigationBarTitle)
        .task {
            await downloadStories()
        }
        .onAppear {
            if router.selectedTab == .home {
                isVisible = true 
            }
            if !isShowingStories {
                stories = authors.map { $0 }
            }
        }
        .onChange(of: isShowingStories) { _, newValue in
            if newValue {
                analytics.enteredStories()
            } else {
                analytics.closedStories()
                stories = authors.map { $0 }
            }
        }
        .onDisappear { isVisible = false }
        .onChange(of: isVisible) { 
            if isVisible {
                analytics.showedHome()
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
