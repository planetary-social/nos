import SwiftUI
import Combine
import CoreData
import Dependencies
import Logger

/// Displays a list of cells that let the user know when other users interact with their notes / follow them.
struct NotificationsView: View {

    @Environment(RelayService.self) private var relayService
    @EnvironmentObject private var router: Router
    @Environment(CurrentUser.self) private var currentUser
    @Dependency(\.analytics) private var analytics
    @Dependency(\.pushNotificationService) private var pushNotificationService
    @Dependency(\.persistenceController) private var persistenceController

    @FetchRequest private var outOfNetworkNotifications: FetchedResults<NosNotification>
    @FetchRequest private var inNetworkNotifications: FetchedResults<NosNotification>
    @FetchRequest private var followNotifications: FetchedResults<NosNotification>

    @State private var relaySubscriptions = SubscriptionCancellables()
    @State private var isVisible = false
    @State private var selectedTab = 1

    private let maxNotificationsToShow = 100

    init(user: Author?) {
        let followsRequest = Self.createFollowsFetchRequest(for: user, limit: maxNotificationsToShow)
        let networkRequests = Self.createNetworkFetchRequests(for: user, limit: maxNotificationsToShow)

        _followNotifications = FetchRequest(fetchRequest: followsRequest)
        _outOfNetworkNotifications = FetchRequest(fetchRequest: networkRequests.outOfNetwork)
        _inNetworkNotifications = FetchRequest(fetchRequest: networkRequests.inNetwork)
    }

    /// Creates the follows notification fetch requests for all notifications and follows.
    ///
    /// This is implemented as a static function because it's used during initialization
    /// and doesn't require access to instance properties.
    ///
    /// - Parameters:
    ///   - user: The user to fetch notifications for. If nil, returns empty requests.
    ///   - limit: The maximum number of notifications to fetch.
    /// - Returns: A fetch request for follows notifications.
    private static func createFollowsFetchRequest(for user: Author?, limit: Int) -> NSFetchRequest<NosNotification> {
        if let user {
            return NosNotification.followsRequest(for: user, limit: limit)
        } else {
            let emptyRequest = NosNotification.emptyRequest()
            return emptyRequest
        }
    }

    /// Creates the network-specific notification fetch requests.
    ///
    /// This is implemented as a static function because it's used during initialization
    /// and doesn't require access to instance properties.
    ///
    /// - Parameters:
    ///   - user: The user to fetch notifications for. If nil, returns empty requests.
    ///   - limit: The maximum number of notifications to fetch.
    /// - Returns: A tuple containing fetch requests for in-network and out-of-network notifications.
    private static func createNetworkFetchRequests(for user: Author?, limit: Int) -> (
        outOfNetwork: NSFetchRequest<NosNotification>,
        inNetwork: NSFetchRequest<NosNotification>
    ) {
        if let user {
            return (
                outOfNetwork: NosNotification.outOfNetworkRequest(for: user, limit: limit),
                inNetwork: NosNotification.inNetworkRequest(for: user, limit: limit)
            )
        } else {
            let emptyRequest = NosNotification.emptyRequest()
            return (outOfNetwork: emptyRequest, inNetwork: emptyRequest)
        }
    }

    private func subscribeToNewEvents() async {
        await cancelSubscriptions()

        guard let currentUserKey = currentUser.author?.hexadecimalPublicKey else {
            return
        }

        let filter = Filter(
            kinds: [.text, .zapReceipt],
            pTags: [currentUserKey],
            limit: 100,
            keepSubscriptionOpen: false
        )
        let subscriptions = await relayService.fetchEvents(matching: filter)
        relaySubscriptions.append(subscriptions)
    }

    private func cancelSubscriptions() async {
        relaySubscriptions.removeAll()
    }

    private func markAllNotificationsRead() async {
        if currentUser.author != nil {
            do {
                let backgroundContext = persistenceController.backgroundViewContext
                try await NosNotification.markAllAsRead(in: backgroundContext)
                await pushNotificationService.updateBadgeCount()
            } catch {
                Log.optional(error, "Error marking notifications as read")
            }
        }
    }

    var body: some View {
        NosNavigationStack(path: $router.notificationsPath) {
            tabBarContent
            .background(Color.appBg)
            .padding(.top, 1)
            .nosNavigationBar("notifications")
            .navigationBarItems(leading: SideMenuButton())
            .refreshable {
                await subscribeToNewEvents()
            }
            .onAppear {
                if router.selectedTab == .notifications {
                    isVisible = true
                }
                pushNotificationService.requestNotificationPermissionsFromUser()
            }
            .onDisappear {
                isVisible = false
            }
            .onChange(of: isVisible) {
                Task { await markAllNotificationsRead() }
                if isVisible {
                    analytics.showedNotifications()
                    Task {
                        await subscribeToNewEvents()
                    }
                } else {
                    Task { await cancelSubscriptions() }
                }
            }
        }
    }

    private var tabBarContent: some View {
        VStack(spacing: 0) {
            // Custom tab bar at the top
            Divider()
                .overlay(Color.cardDividerTop)
                .shadow(color: .cardDividerTopShadow, radius: 0, x: 0, y: 1)
            HStack(spacing: 0) {
                TabButton(
                    title: String(localized: "follows"),
                    isSelected: selectedTab == 0
                ) {
                    selectedTab = 0
                }
                Spacer()
                TabButton(
                    title: String(localized: "inNetwork"),
                    isSelected: selectedTab == 1
                ) {
                    selectedTab = 1
                }
                Spacer()
                TabButton(
                    title: String(localized: "outOfNetwork"),
                    isSelected: selectedTab == 2
                ) {
                    selectedTab = 2
                }
            }
            // Constrains the width to prevent the content from becoming too wide
            .frame(maxWidth: 600)
            .padding(.horizontal, 36)
            .background(LinearGradient.cardBackground)
            .background(
                Color.card3d
                    .offset(y: 4.5)
                    .shadow(
                        color: Color.cardShadowBottom,
                        radius: 5,
                        x: 0,
                        y: 4
                    )
            )

            // Content based on selected tab
            TabView(selection: $selectedTab) {
                NotificationTabView(
                    notifications: followNotifications,
                    currentUser: currentUser,
                    maxNotificationsToShow: maxNotificationsToShow,
                    tag: 0
                )
                .tag(0)

                NotificationTabView(
                    notifications: inNetworkNotifications,
                    currentUser: currentUser,
                    maxNotificationsToShow: maxNotificationsToShow,
                    tag: 1
                )
                .tag(1)

                NotificationTabView(
                    notifications: outOfNetworkNotifications,
                    currentUser: currentUser,
                    maxNotificationsToShow: maxNotificationsToShow,
                    tag: 2
                )
                .tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
    }
}

/// A single notification cell that contains a follow event or a other event types in the notifications list
private struct NotificationCell: View {
    @Dependency(\.persistenceController) private var persistenceController
    let notification: NosNotification
    let user: Author

    var body: some View {
        if let eventID = notification.event?.identifier,
            let event = Event.find(
            by: eventID,
            context: persistenceController.viewContext
            ) {
            NotificationCard(
                viewModel: NotificationViewModel(
                    note: event,
                    user: user,
                    date: notification.createdAt ?? .distantPast
                )
            )
            .id(event.id)
        } else if let followerKey = notification.follower?.hexadecimalPublicKey, let follower = try? Author.find(
            by: followerKey,
            context: persistenceController.viewContext
        ) {
            FollowsNotificationCard(
                author: follower,
                viewModel: NotificationViewModel(
                    follower: follower,
                    date: notification.createdAt ?? .distantPast
                )
            )
            .id(notification.event?.id)
        }
    }
}

/// A custom tab button that displays a title and changes appearance based on selection state.
/// Used in the notifications view's tab bar for switching between different notification categories.
private struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.bold)
                .padding(.vertical, 12)
                .foregroundColor(isSelected ? .primaryTxt : .secondaryTxt)
        }
    }
}

/// A scrollable view that displays a list of notifications for a specific category
/// (follows, in-network, or out-of-network).
private struct NotificationTabView: View {
    let notifications: FetchedResults<NosNotification>
    let currentUser: CurrentUser
    let maxNotificationsToShow: Int
    let tag: Int
    var body: some View {
        ScrollView(.vertical) {
            LazyVStack {
                /// The fetch request for events has a `fetchLimit` set but it doesn't work, so we limit the
                /// number of views displayed here and that appears to prevent @FetchRequest from loading all the
                /// records into memory.
                ForEach(0..<maxNotificationsToShow, id: \.self) { index in
                    if let notification = notifications[safe: index], let user = currentUser.author {
                        NotificationCell(notification: notification, user: user)
                            .tag(tag)
                            .padding(.horizontal, 11)
                            .padding(.top, 16)
                            .readabilityPadding()
                    }
                }
            }
            .padding(.vertical, 16)
        }
        .overlay(Group {
            if notifications.isEmpty {
                Text("noNotifications")
            }
        })
        .doubleTapToPop(tab: .notifications) { proxy in
            if let firstNotification = notifications.first {
                proxy.scrollTo(firstNotification.id)
            }
        }
    }
}

struct NotificationsView_Previews: PreviewProvider {

    static var previewData = PreviewData()

    static var previewContext = previewData.previewContext

    static var alice: Author {
        previewData.alice
    }

    static var bob: Author {
        previewData.bob
    }

    static var eve: Author {
        previewData.eve
    }

    static func createTestData(in context: NSManagedObjectContext) {
        // Sets up network relationship
        let bobFollowsAlice = Follow(context: context)
        bobFollowsAlice.source = bob
        bobFollowsAlice.destination = alice
        bob.addToFollows(bobFollowsAlice)

        // Creates a follow notification
        let followNotification = NosNotification(context: context)
        followNotification.createdAt = .now
        followNotification.user = bob
        followNotification.follower = alice
        followNotification.event?.kind = 3

        // Creates mention note from Alice (in-network since Bob follows Alice)
        let inNetworkNote = Event(context: context)
        inNetworkNote.content = "Hello @bob!"
        inNetworkNote.kind = EventKind.text.rawValue
        inNetworkNote.createdAt = .now
        inNetworkNote.author = alice
        let inNetworkAuthorRef = AuthorReference(context: context)
        inNetworkAuthorRef.pubkey = bob.hexadecimalPublicKey
        inNetworkNote.authorReferences = NSMutableOrderedSet(array: [inNetworkAuthorRef])
        try? inNetworkNote.sign(withKey: KeyFixture.alice)

        let inNetworkNotification = NosNotification(context: context)
        inNetworkNotification.createdAt = .now
        inNetworkNotification.user = bob
        inNetworkNotification.event = inNetworkNote

        // Creates mention from Eve (out-of-network since Bob doesn't follow Eve)
        let outOfNetworkNote = Event(context: context)
        outOfNetworkNote.content = "Hey @bob!"
        outOfNetworkNote.createdAt = .now
        outOfNetworkNote.author = eve
        let outOfNetworkAuthorRef = AuthorReference(context: context)
        outOfNetworkAuthorRef.pubkey = bob.hexadecimalPublicKey
        outOfNetworkNote.authorReferences = NSMutableOrderedSet(array: [outOfNetworkAuthorRef])
        try? outOfNetworkNote.sign(withKey: KeyFixture.eve)

        let outOfNetworkNotification = NosNotification(context: context)
        outOfNetworkNotification.createdAt = .now
        outOfNetworkNotification.user = bob
        outOfNetworkNotification.event = outOfNetworkNote

        try? context.save()
    }

    static var previews: some View {
        NavigationView {
            NotificationsView(user: bob)
        }
        .inject(previewData: previewData)
        .onAppear { createTestData(in: previewContext) }
    }
}
