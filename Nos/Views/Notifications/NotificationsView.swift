import SwiftUI
import Combine
import CoreData
import Dependencies
import Logger

/// Displays a list of cells that let the user know when other users interact with their notes.
struct NotificationsView: View {
    
    @Environment(RelayService.self) private var relayService
    @EnvironmentObject private var router: Router
    @Dependency(\.analytics) private var analytics
    @Dependency(\.pushNotificationService) private var pushNotificationService
    @Dependency(\.persistenceController) private var persistenceController

    @FetchRequest private var events: FetchedResults<Event>
    @State private var relaySubscriptions = SubscriptionCancellables()
    @State private var isVisible = false
    
    // Probably the logged in user should be in the @Environment eventually
    private var user: Author?
    private let maxNotificationsToShow = 100
    
    init(user: Author?) {
        self.user = user
        if let user {
            _events = FetchRequest(fetchRequest: Event.all(notifying: user, limit: maxNotificationsToShow))
        } else {
            _events = FetchRequest(fetchRequest: Event.emptyRequest())
        }
    }    
    
    func subscribeToNewEvents() async {
        await cancelSubscriptions()
        
        guard let currentUserKey = user?.hexadecimalPublicKey else {
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
        if user != nil {
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
                    /// number of views displayed here and that appears to prevent @FetchRequest from loading all the
                    /// records into memory.
                    ForEach(0..<maxNotificationsToShow, id: \.self) { index in
                        if let event = events[safe: index], let user {
                            NotificationCard(viewModel: NotificationViewModel(note: event, user: user))
                                .padding(.horizontal, 15)
                                .padding(.bottom, 10)
                                .readabilityPadding()
                                .id(event.id)
                        }
                    }
                }
                .padding(.top, 10)
            }
            .overlay(Group {
                if events.isEmpty {
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
            .onTabAppear(.notifications) {
                pushNotificationService.requestNotificationPermissionsFromUser()
                analytics.showedNotifications()
                await subscribeToNewEvents()
                await markAllNotificationsRead()
            }
            .onTabDisappear(.notifications) {
                await cancelSubscriptions()
                await markAllNotificationsRead()
            }
            .doubleTapToPop(tab: .notifications) { proxy in
                if let firstEvent = events.first {
                    proxy.scrollTo(firstEvent.id)
                }
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
