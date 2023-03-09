//
//  NotificationsView.swift
//  Nos
//
//  Created by Matthew Lorentz on 3/2/23.
//

import SwiftUI
import CoreData

/// Displays a list of cells that let the user know when other users interact with their notes.
struct NotificationsView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @EnvironmentObject private var relayService: RelayService
    
    @EnvironmentObject private var router: Router

    private var eventRequest: FetchRequest<Event> = FetchRequest(fetchRequest: Event.emptyRequest())
    private var events: FetchedResults<Event> { eventRequest.wrappedValue }
    
    // Probably the logged in user should be in the @Environment eventually
    private var user: Author?
    
    init(user: Author?) {
        self.user = user
        if let user {
            eventRequest = FetchRequest(fetchRequest: Event.allNotifications(for: user))
        }
    }
    
    var body: some View {
        NavigationStack(path: $router.path) {
            ScrollView(.vertical) {
                LazyVStack {
                    ForEach(events.unmuted) { event in
                        if let user {
                            NotificationCard(note: event, user: user)
                        }
                    }
                }
                if events.isEmpty {
                    Localized.noNotifications.view
                }
            }
            .padding(.top, 1)
            .navigationDestination(for: Event.self) { note in
                RepliesView(note: note)
            }
            .navigationDestination(for: Author.self) { author in
                ProfileView(author: author)
            }
            .navigationDestination(for: AppView.Destination.self) { destination in
                if destination == AppView.Destination.settings {
                    SettingsView()
                }
            }
        }
    }
}

struct NotificationCard: View {
    
    private let note: Event
    private let user: Author
    private let actionText: String?
    private let authorName: String
    
    @EnvironmentObject private var router: Router
    
    init(note: Event, user: Author) {
        self.note = note
        self.user = user
        
        authorName = note.author?.safeName ?? "someone"
        
        if note.isReply(to: user) {
            actionText = "replied to your note:"
        } else if note.references(author: user) {
            actionText = "mentioned you:"
        } else {
            actionText = nil
        }
    }
    
    var body: some View {
        if let author = note.author {
            Button {
                router.path.append(note.rootNote())
            } label: {
                HStack {
                    AvatarView(imageUrl: author.profilePhotoURL, size: 40)
                    
                    VStack {
                        if let actionText {
                            HStack(spacing: 4) {
                                Text(authorName)
                                    .font(.body)
                                    .bold()
                                    .foregroundColor(.primaryTxt)
                                Text(actionText)
                                    .font(.body)
                                    .foregroundColor(.primaryTxt)
                                Spacer()
                            }
                        }
                        HStack {
                            Text("\"\(note.content ?? "null")\"")
                                .lineLimit(1)
                                .font(.body)
                                .foregroundColor(.primaryTxt)
                            if let elapsedTime = note.createdAt?.elapsedTimeFromNowString() {
                                Text(elapsedTime)
                                    .lineLimit(1)
                                    .font(.body)
                                    .foregroundColor(.secondaryTxt)
                            }
                            Spacer()
                        }
                    }
                    Spacer()
                }
                .padding(10)
                .background(
                    LinearGradient(
                        colors: [Color.cardBgTop, Color.cardBgBottom],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(20)
                .padding(.horizontal, 15)
                .padding(.top, 15)
            }
            .buttonStyle(CardButtonStyle())
        }
    }
}

struct NotificationsView_Previews: PreviewProvider {
    
    static var persistenceController = {
        let controller = PersistenceController.preview
        let context = controller.container.viewContext
        
        return controller
    }()
    
    static var previewContext = persistenceController.container.viewContext
    static var relayService = RelayService(persistenceController: persistenceController)
    
    static var emptyPersistenceController = PersistenceController.empty
    static var emptyPreviewContext = emptyPersistenceController.container.viewContext
    static var emptyRelayService = RelayService(persistenceController: emptyPersistenceController)
    
    static var router = Router()
    
    static var alice: Author = {
        let author = Author(context: previewContext)
        author.hexadecimalPublicKey = KeyFixture.alice.publicKeyHex
        author.name = "Alice"
        return author
    }()
    
    static var bob: Author = {
        let author = Author(context: previewContext)
        author.hexadecimalPublicKey = KeyFixture.bob.publicKeyHex
        author.name = "Bob"
        
        return author
    }()
    
    static func createTestData(in context: NSManagedObjectContext) {
        let mentionNote = Event(context: context)
        mentionNote.content = "Hello, bob!"
        mentionNote.kind = 1
        mentionNote.createdAt = .now
        mentionNote.author = alice
        let authorRef = AuthorReference(context: context)
        authorRef.pubkey = bob.hexadecimalPublicKey
        mentionNote.authorReferences = NSMutableOrderedSet(array: [authorRef])
        try! mentionNote.sign(withKey: KeyFixture.alice)
        
        let bobNote = Event(context: context)
        bobNote.content = "Hello, world!"
        bobNote.kind = 1
        bobNote.author = bob
        bobNote.createdAt = .now
        try! bobNote.sign(withKey: KeyFixture.bob)
        
        let replyNote = Event(context: context)
        replyNote.content = "Top of the morning to you, bob! This text should be truncated."
        replyNote.kind = 1
        replyNote.createdAt = .now
        replyNote.author = alice
        let eventRef = EventReference(context: context)
        eventRef.referencedEvent = bobNote
        eventRef.referencingEvent = replyNote
        replyNote.eventReferences = NSMutableOrderedSet(array: [eventRef])
        try! replyNote.sign(withKey: KeyFixture.alice)
        
        try! context.save()
    }
    
    static var previews: some View {
        NavigationView {
            NotificationsView(user: bob)
        }
        .environment(\.managedObjectContext, previewContext)
        .environmentObject(relayService)
        .environmentObject(router)
        .onAppear { createTestData(in: previewContext) }
    }
}
