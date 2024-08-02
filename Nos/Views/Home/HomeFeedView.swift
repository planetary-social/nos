import SwiftUI
import CoreData
import Combine
import Dependencies

struct HomeFeedView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var relayService: RelayService
    @EnvironmentObject private var router: Router
    @Environment(CurrentUser.self) var currentUser
    @Dependency(\.refreshController) private var refreshController
    @ObservationIgnored @Dependency(\.analytics) private var analytics

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

    @State private var startRefreshing = false
    @State private var showRelayPicker = false
    @State private var selectedRelay: Relay? 

    init(user: Author) {
        self.user = user
    }
    
    var homeFeedFetchRequest: NSFetchRequest<Event> {
        Event.homeFeed(
            for: user,
            before: refreshController.lastRefreshDate ??
                Date(timeIntervalSince1970: Date.now.timeIntervalSince1970 + Double(Self.staticLoadTime)),
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
    
    var navigationBarTitle: LocalizedStringResource {
        if let relayName = selectedRelay?.host {
            LocalizedStringResource(stringLiteral: relayName)
        } else {
            .localizable.accountsIFollow
        }
    }

    var body: some View {
        ZStack {
            PagedNoteListView(
                databaseFilter: homeFeedFetchRequest,
                relayFilter: homeFeedFilter,
                relay: selectedRelay,
                managedObjectContext: viewContext,
                tab: .home,
                refreshController: refreshController,
                header: {
                    EmptyView()
                },
                emptyPlaceholder: {
                    VStack {
                        Text(.localizable.noEvents)
                            .padding()
                    }
                    .frame(minHeight: 300)
                },
                onRefresh: {
                    refreshController.setLastRefreshDate(.now)
                }
            )
            .padding(0)

            NewNotesButton(
                user: user,
                lastRefreshDate: refreshController.lastRefreshDate ?? .now,
                seenOn: selectedRelay
            ) {
                refreshController.setShouldRefresh(true)
            }

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
                    refreshController.setLastRefreshDate(.now + Self.staticLoadTime)
                    Task {
                        withAnimation {
                            showRelayPicker = false
                        }
                    }
                }
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
            ToolbarItem(placement: .navigationBarTrailing) {
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
        .padding(.top, 1)
        .nosNavigationBar(title: navigationBarTitle)
        .onAppear {
            if router.selectedTab == .home {
                isVisible = true 
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

struct NewNotesButton: View {
    @FetchRequest var newNotes: FetchedResults<Event>
    var action: (() async -> Void)?

    init(user: Author, lastRefreshDate: Date, seenOn: Relay?, action: @escaping () async -> Void) {
        let request = Event.homeFeed(for: user, after: lastRefreshDate, seenOn: seenOn)
        _newNotes = FetchRequest(fetchRequest: request)
        self.action = action
    }

    var body: some View {
        if newNotes.isEmpty {
            EmptyView()
        } else {
            VStack {
                SecondaryActionButton(
                    title: "New notes available",
                    font: .clarity(.semibold, textStyle: .footnote),
                    action: action
                )
                Spacer()
            }
            .padding(8)
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
