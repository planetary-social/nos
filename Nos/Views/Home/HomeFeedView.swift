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
        timeIntervalSince1970: Date.now.timeIntervalSince1970 + Double(Self.initialLoadTime)
    )
    @State private var isVisible = false
    @State private var relaySubscriptions = [SubscriptionCancellable]()
    @State private var performingInitialLoad = true
    @State private var isShowingRelayList = false
    static let initialLoadTime = 2

    @ObservedObject var user: Author

    @State private var stories: [Author] = []
    @State private var selectedStoryAuthor: Author?
    @State private var storiesCutoffDate = Calendar.current.date(byAdding: .day, value: -2, to: .now)!

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
    
    /// Downloads the data we need to show stories. 
    func downloadStories() async {
        relaySubscriptions.removeAll()
        
        let followedKeys = await Array(currentUser.socialGraph.followedKeys)
        
        if !followedKeys.isEmpty {
            let textFilter = Filter(
                authorKeys: followedKeys, 
                kinds: [.text, .delete, .repost, .longFormContent, .report], 
                since: storiesCutoffDate,
                shouldKeepSubscriptionOpen: true
            )
            let textSubs = await relayService.fetchEvents(matching: textFilter)
            relaySubscriptions.append(textSubs)
        }
    }
    
    var body: some View {
        ZStack {
            let homeFeedFilter = Filter(
                authorKeys: user.followedKeys, 
                kinds: [.text, .delete, .repost, .longFormContent, .report], 
                limit: 100, 
                since: nil,
                shouldKeepSubscriptionOpen: true
            )
            PagedNoteListView(
                databaseFilter: Event.homeFeed(for: user, before: lastRefreshDate), 
                relayFilter: homeFeedFilter,
                context: viewContext,
                tab: .home,
                header: {
                    AuthorStoryCarousel(
                        authors: $stories, 
                        selectedStoryAuthor: $selectedStoryAuthor
                    )
                },
                emptyPlaceholder: {
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
            
            if performingInitialLoad {
                FullscreenProgressView(
                    isPresented: $performingInitialLoad,
                    hideAfter: .now() + .seconds(Self.initialLoadTime)
                )
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
                        isShowingRelayList = true
                    } label: {
                        HStack(spacing: 3) {
                            Image("relay-left")
                                .colorMultiply(relayService.numberOfConnectedRelays > 0 ? .white : .red)
                            Text("\(relayService.numberOfConnectedRelays)")
                                .font(.clarity(.bold, textStyle: .title3))
                                .foregroundColor(.primaryTxt)
                            Image("relay-right")
                                .colorMultiply(relayService.numberOfConnectedRelays > 0 ? .white : .red)
                        }
                    }
                    .sheet(isPresented: $isShowingRelayList) {
                        NavigationView {
                            RelayView(author: user)
                        }
                    }
                }
            }
        }
        .padding(.top, 1)
        .nosNavigationBar(title: isShowingStories ? .localizable.stories : .localizable.homeFeed)
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

struct ContentView_Previews: PreviewProvider {
    
    static var previewData = PreviewData()
    static var persistenceController = PersistenceController.preview
    static var previewContext = persistenceController.container.viewContext
    static var relayService = previewData.relayService
    
    static var emptyPersistenceController = PersistenceController.empty
    static var emptyPreviewContext = emptyPersistenceController.container.viewContext
    static var emptyRelayService = previewData.relayService
    
    static var router = Router()
    
    static var currentUser = previewData.currentUser
    
    static var shortNote: Event {
        let note = Event(context: previewContext)
        note.identifier = "p1"
        note.kind = 1
        note.content = "Hello, world!"
        note.author = currentUser.author
        return note
    }
    
    static var longNote: Event {
        let note = Event(context: previewContext)
        note.identifier = "p2"
        note.kind = 1
        note.content = .loremIpsum(5)
        note.author = currentUser.author
        return note
    }
    
    static var user: Author {
        let author = Author(context: previewContext)
        author.hexadecimalPublicKey = "d0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e"
        return author
    }
    
    static var previews: some View {
        HomeFeedView(user: user)
            .inject(previewData: previewData)
            .onAppear {
                print(shortNote)
                print(longNote)
            }
        
        HomeFeedView(user: user)
            .environment(\.managedObjectContext, emptyPreviewContext)
            .environmentObject(emptyRelayService)
            .environmentObject(router)
            .environment(currentUser)
    }
}
