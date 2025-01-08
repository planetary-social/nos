import SwiftUI
import Combine
import CoreData
import Dependencies
import Logger

/// Displays a list of cells that let the user know when other users interact with their notes / follow them.
struct NotificationsView: View {

    @Environment(RelayService.self) private var relayService
    @EnvironmentObject private var router: Router
    @Dependency(\.analytics) private var analytics
    @Dependency(\.pushNotificationService) private var pushNotificationService
    @Dependency(\.persistenceController) private var persistenceController

    @FetchRequest private var notifications: FetchedResults<NosNotification>
    @State private var relaySubscriptions = SubscriptionCancellables()
    @State private var isVisible = false

    @Environment(CurrentUser.self) private var currentUser
    private let maxNotificationsToShow = 100

    init(user: Author?) {
        if let user {
            let request = NosNotification.all(
                notifying: user,
                limit: maxNotificationsToShow
            )
            _notifications = FetchRequest(fetchRequest: request)
        } else {
            _notifications = FetchRequest(fetchRequest: NosNotification.emptyRequest())
        }
    }

    func subscribeToNewEvents() async {
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

    func cancelSubscriptions() async {
        relaySubscriptions.removeAll()
    }

    func markAllNotificationsRead() async {
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
            ScrollView(.vertical) {
                LazyVStack {
                    /// The fetch request for events has a `fetchLimit` set but it doesn't work, so we limit the
                    /// number of views displayed here and ?that appears to prevent @FetchRequest from loading all the
                    /// records into memory.
                    ForEach(0..<maxNotificationsToShow, id: \.self) { index in
                        if let notification = notifications[safe: index], let user = currentUser.author {
                            NotificationCell(notification: notification, user: user)
                        }
                    }
                }
                .padding(.top, 10)
            }
            .overlay(Group {
                if notifications.isEmpty {
                    Text("noNotifications")
                }
            })
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
            .doubleTapToPop(tab: .notifications) { proxy in
                if let firstNotification = notifications.first {
                    proxy.scrollTo(firstNotification.id)
                }
            }
        }
    }
}

/// A single notification cell that contains a follow event or a other event types in the notifications list
private struct NotificationCell: View {
    @Dependency(\.persistenceController) private var persistenceController
    let notification: NosNotification
    let user: Author

    var body: some View {
        if let event = Event.find(by: notification.eventID ?? "", context: persistenceController.viewContext) {
            NotificationCard(
                viewModel: NotificationViewModel(
                    note: event,
                    user: user,
                    date: notification.createdAt ?? .distantPast
                )
            )
            .padding(.horizontal, 15)
            .padding(.bottom, 10)
            .readabilityPadding()
            .id(notification.id)
        } else if let followerKey = notification.follower?.hexadecimalPublicKey, let follower = try? Author.find(
            by: followerKey,
            context: persistenceController.viewContext
        ) {
            NotificationCard(
                viewModel: NotificationViewModel(
                    follower: follower,
                    date: notification.createdAt ?? .distantPast
                )
            )
            .padding(.horizontal, 15)
            .padding(.bottom, 10)
            .readabilityPadding()
            .id(notification.id)
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
    
    static func createTestData(in context: NSManagedObjectContext) {
        let mentionNote = Event(context: context)
        mentionNote.content = "Hello, bob!"
        mentionNote.kind = 1
        mentionNote.createdAt = .now
        mentionNote.author = alice
        let authorRef = AuthorReference(context: context)
        authorRef.pubkey = bob.hexadecimalPublicKey
        mentionNote.authorReferences = NSMutableOrderedSet(array: [authorRef])
        try? mentionNote.sign(withKey: KeyFixture.alice)
        
        let bobNote = Event(context: context)
        bobNote.content = "Hello, world!"
        bobNote.kind = 1
        bobNote.author = bob
        bobNote.createdAt = .now
        try? bobNote.sign(withKey: KeyFixture.bob)
        
        let replyNote = Event(context: context)
        replyNote.content = "Top of the morning to you, bob! This text should be truncated."
        replyNote.kind = 1
        replyNote.createdAt = .now
        replyNote.author = alice
        let eventRef = EventReference(context: context)
        eventRef.referencedEvent = bobNote
        eventRef.referencingEvent = replyNote
        replyNote.eventReferences = NSMutableOrderedSet(array: [eventRef])
        try? replyNote.sign(withKey: KeyFixture.alice)
        
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
