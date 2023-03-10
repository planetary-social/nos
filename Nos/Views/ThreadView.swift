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
    
    /// Takes a root `Event`, and an array of all replies to the parent note of this thread,
    /// and builds the longest possible thread from that array of all replies.
    init(root: Event, allReplies: [Event]) {
        self.root = root
        
        var currentEvent: Event = root
        while true {
            if let nextEvent = allReplies
                .first(where: {
                    ($0.eventReferences?.lastObject as? EventReference)?.referencedEvent?.identifier == currentEvent.identifier
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
            NoteButton(note: root, showFullMessage: true)
                .padding(.horizontal)
            ForEach(thread) { event in
                VStack {
                    ZStack {
                        Path { path in
                            path.move(to: CGPoint(x: 35, y: -4))
                            path.addLine(to: CGPoint(x: 35, y: 15))
                        }
                        .stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .fill(Color.secondaryTxt)
                        NoteButton(note: event)
                            .padding(.horizontal)
                    }
                }
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
    
    static var shortNote: Event {
        let note = Event(context: previewContext)
        note.kind = 1
        note.content = "Hello, world!"
        note.author = user
        return note
    }
    
    static var longNote: Event {
        let note = Event(context: previewContext)
        note.kind = 1
        note.content = .loremIpsum(5)
        note.author = user
        return note
    }
    
    static var user: Author {
        let author = Author(context: previewContext)
        author.hexadecimalPublicKey = "d0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e"
        return author
    }
    
    static var previews: some View {
        ThreadView(root: shortNote, allReplies: [])
            .environment(\.managedObjectContext, emptyPreviewContext)
            .environmentObject(emptyRelayService)
            .environmentObject(router)
    }
}
