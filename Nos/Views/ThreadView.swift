//
//  ThreadView.swift
//  Nos
//
//  Created by Shane Bielefeld on 3/3/23.
//

import SwiftUI

struct ThreadView: View {
    
    var root: Event
    
    var thread: [Event] = []
    
    @EnvironmentObject private var router: Router
    
    /// Takes a root `Event`, and an array of all replies to the parent note of this thread,
    /// and builds the longest possible thread from that array of all replies.
    init(root: Event, allReplies: [Event]) {
        self.root = root
        
        var currentEvent: Event = root
        while true {
            if let nextEvent = allReplies
                .first(where: {
                    ($0.eventReferences?.lastObject as? EventReference)?.eventId == currentEvent.identifier
                }) {
                thread.append(nextEvent)
                currentEvent = nextEvent
            } else {
                break
            }
        }
    }
    
    var body: some View {
        LazyVStack {
            NoteButton(note: root, tapAction: { event in
                router.push(event)
            })
            .padding(.top, 15)
            ForEach(thread) { event in
                VStack {
                    ZStack {
                        Path { path in
                            path.move(to: CGPoint(x: 35, y: -4))
                            path.addLine(to: CGPoint(x: 35, y: 15))
                        }
                        .stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .fill(Color.secondaryText)
                        NoteButton(note: event, tapAction: { event in
                            router.push(event)
                        })
                        .padding(.top, 15)
                    }
                }
                .readabilityPadding()
            }
        }
    }
}

struct ThreadView_Previews: PreviewProvider {
    static var persistenceController = PersistenceController.preview
    static var previewContext = persistenceController.container.viewContext
    static var relayService = RelayService(persistenceController: persistenceController)
    static var router = Router()
    
    static var emptyPersistenceController = PersistenceController.empty
    static var emptyPreviewContext = emptyPersistenceController.container.viewContext
    static var emptyRelayService = RelayService(persistenceController: emptyPersistenceController)

    static var currentUser: CurrentUser = {
        let currentUser = CurrentUser(persistenceController: persistenceController)
        currentUser.viewContext = previewContext
        currentUser.relayService = relayService
        Task { await currentUser.setKeyPair(KeyFixture.keyPair) }
        return currentUser
    }()
    
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
        
    static var rootNote: Event {
        let bobNote = Event(context: previewContext)
        bobNote.content = "Hello, world!"
        bobNote.identifier = "root"
        bobNote.kind = 1
        bobNote.author = bob
        bobNote.createdAt = .now
        try! bobNote.sign(withKey: KeyFixture.bob)
        
        return bobNote
    }
    
    static var replyNote: Event {
        let replyNote = Event(context: previewContext)
        replyNote.content = "Top of the morning to you, bob! This text should be truncated."
        replyNote.kind = 1
        replyNote.createdAt = .now
        replyNote.author = alice
    
        let eventRef = EventReference(context: previewContext)
        eventRef.eventId = "root"
        eventRef.referencedEvent = rootNote
        eventRef.referencingEvent = replyNote
        replyNote.eventReferences = NSMutableOrderedSet(array: [eventRef])
        try! replyNote.sign(withKey: KeyFixture.alice)
        try! previewContext.save()
        
        return replyNote
    }
    
    static var secondReply: Event {
        let replyNote = Event(context: previewContext)
        replyNote.content = "Top of the morning to you, bob! This text should be truncated."
        replyNote.kind = 1
        replyNote.createdAt = .now
        replyNote.author = alice
    
        let eventRef = EventReference(context: previewContext)
        eventRef.eventId = "root"
        eventRef.referencedEvent = rootNote
        eventRef.referencingEvent = replyNote
        replyNote.eventReferences = NSMutableOrderedSet(array: [eventRef])
        try! replyNote.sign(withKey: KeyFixture.alice)
        try! previewContext.save()
        
        return replyNote
    }
    
    static var user: Author {
        let author = Author(context: previewContext)
        author.hexadecimalPublicKey = "d0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e"
        return author
    }
    
    static var previews: some View {
        ThreadView(root: rootNote, allReplies: [replyNote, secondReply])
            .environment(\.managedObjectContext, emptyPreviewContext)
            .environmentObject(emptyRelayService)
            .environmentObject(router)
            .environmentObject(currentUser)
    }
}
