//
//  ThreadRootView.swift
//  Nos - This is the root note card for threads.
//
//  Created by Rabble on 10/16/23.
//

import SwiftUI

struct ThreadRootView: View {
    var root: Event
    var tapAction: ((Event) -> Void)?
    
    var thread: [Event] = []
    
    @EnvironmentObject private var router: Router
    
    init(root: Event, tapAction: ((Event) -> Void)?) {
        self.root = root
        self.tapAction = tapAction
    }
    
    var body: some View {
        LazyVStack {
            NoteButton(note: root, hideOutOfNetwork: false, tapAction: tapAction)
            .scaleEffect(0.9) // Make the button 80% of its original size.
            .offset(y: 50) // Move the button downward by 40 pixels.
            .clipped() // Ensure that the part of the button moved outside of its container is not visible.
        }
        .overlay(
            LinearGradient(gradient: Gradient(stops: [
                .init(color: Color.clear, location: 0),
                .init(color: Color.clear, location: 0.5), // Add more clear stops
                .init(color: Color.appBg, location: 1)
            ]), startPoint: .center,
                endPoint: .bottom)
        )
        
        .onTapGesture {
            self.tapAction?(self.root) // Use optional chaining to call tapAction.
        }
    }
}


struct ThreadRootView_Previews: PreviewProvider {
    static var previewData = PreviewData()
    static var persistenceController = PersistenceController.preview
    static var previewContext = persistenceController.container.viewContext
    static var relayService = previewData.relayService
    static var router = Router()
    
    static var emptyPersistenceController = PersistenceController.empty
    static var emptyPreviewContext = emptyPersistenceController.container.viewContext
    static var emptyRelayService = previewData.relayService
    static var currentUser = previewData.currentUser
    
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
        do {
            try bobNote.sign(withKey: KeyFixture.bob)
        } catch {
            print(error)
        }
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
        do {
            try replyNote.sign(withKey: KeyFixture.alice)
            try previewContext.save()
        } catch {
            print(error)
        }
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
        do {
            try replyNote.sign(withKey: KeyFixture.alice)
            try previewContext.save()
        } catch {
            print(error)
        }
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
