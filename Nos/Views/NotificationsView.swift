//
//  NotificationsView.swift
//  Nos
//
//  Created by Matthew Lorentz on 3/2/23.
//

import SwiftUI
import Combine
import CoreData
import Dependencies
import Logger

/// Displays a list of cells that let the user know when other users interact with their notes.
struct NotificationsView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var relayService: RelayService
    @EnvironmentObject private var router: Router
    @Dependency(\.analytics) private var analytics
    @Dependency(\.pushNotificationService) private var pushNotificationService
    @Dependency(\.persistenceController) private var persistenceController

    private var eventRequest: FetchRequest<Event> = FetchRequest(fetchRequest: Event.emptyRequest())
    private var events: FetchedResults<Event> { eventRequest.wrappedValue }
    @State private var subscriptionIDs = [String]()
    @State private var isVisible = false

    @State private var concecutiveTapsCancellable: AnyCancellable?
    
    // Probably the logged in user should be in the @Environment eventually
    private var user: Author?
    
    init(user: Author?) {
        self.user = user
        if let user {
            eventRequest = FetchRequest(fetchRequest: Event.all(notifying: user))
        }
    }    
    
    func subscribeToNewEvents() async {
        await cancelSubscriptions()
        
        guard let currentUserKey = user?.hexadecimalPublicKey else {
            return
        }
        
        let filter = Filter(
            kinds: [.text], 
            pTags: [currentUserKey], 
            limit: 100
        )
        let subscriptions = await relayService.openSubscriptions(with: filter)
        subscriptionIDs.append(contentsOf: subscriptions)
    }
    
    func cancelSubscriptions() async {
        if !subscriptionIDs.isEmpty {
            await relayService.decrementSubscriptionCount(for: subscriptionIDs)
            subscriptionIDs.removeAll()
        }
    }
    
    func markAllNotificationsRead() async {
        if let user {
            do {
                let backgroundContext = persistenceController.backgroundViewContext
                try await NosNotification.markAllAsRead(for: user, in: backgroundContext)
                await pushNotificationService.updateBadgeCount()
            } catch {
                Log.optional(error, "Error marking notifications as read")
            }
        }
    }
    
    var body: some View {
        NavigationStack(path: $router.notificationsPath) {
            ScrollView(.vertical) {
                LazyVStack {
                    ForEach(events.unmuted) { event in
                        if let user {
                            NotificationCard(viewModel: NotificationViewModel(note: event, user: user))
                                .padding(.horizontal, 15)
                                .readabilityPadding()
                                .id(event.id)
                        }
                    }
                }
                .padding(.top, 10)
            }
            .overlay(Group {
                if events.isEmpty {
                    Localized.noNotifications.view
                }
            })
            .background(Color.appBg)
            .padding(.top, 1)
            .nosNavigationBar(title: .notifications)
            .navigationBarItems(leading: SideMenuButton())
            .navigationDestination(for: Event.self) { note in
                RepliesView(note: note)
            }
            .navigationDestination(for: URL.self) { url in URLView(url: url) }
            .navigationDestination(for: ReplyToNavigationDestination.self) { destination in
                RepliesView(note: destination.note, showKeyboard: true)
            }
            .navigationDestination(for: Author.self) { author in
                ProfileView(author: author)
            }
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
