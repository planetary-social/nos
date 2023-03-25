//
//  AuthorStoryView.swift
//  Nos
//
//  Created by Matthew Lorentz on 3/23/23.
//

import SwiftUI
import CoreData

struct AuthorStoryView: View {
    
    @ObservedObject var author: Author
    var showNextAuthor: () -> Void
    var showPreviousAuthor: () -> Void
    
    @FetchRequest private var notes: FetchedResults<Event>
    
    @State private var currentNote: Event?
    
    init(author: Author, showPreviousAuthor: @escaping () -> Void, showNextAuthor: @escaping () -> Void) {
        self.author = author
        self.showPreviousAuthor = showPreviousAuthor
        self.showNextAuthor = showNextAuthor
        _notes = FetchRequest(fetchRequest: author.storiesRequest())
    }
    
    var body: some View {
        VStack {
            // hack
            let _ = handleNotesChanged(to: notes)
            Spacer()
            if let note = currentNote ?? notes.first {
                NoteButton(
                    note: note,
                    showFullMessage: true,
                    hideOutOfNetwork: false, allowsPush: false
                ) { note in
                    if let currentNoteIndex = notes.firstIndex(of: note) {
                        let nextNoteIndex = notes.index(after: currentNoteIndex)
                        currentNote = notes[nextNoteIndex]
                    } else {
                        currentNote = nil
                    }
                }
                .allowsHitTesting(false)
                .padding()
            } else {
                Text("empty")
            }
            Spacer()
            HStack {
                if let currentNote,
                    let currentNoteIndex = notes.firstIndex(of: currentNote) {
                    ForEach(notes.indices) { noteIndex in
                        let rect = RoundedRectangle(cornerRadius: 21)
                            .frame(maxWidth: .infinity, maxHeight: 3)
                            .padding(1.5)
                            .cornerRadius(21)
                        
                        if noteIndex <= currentNoteIndex {
                            rect.foregroundColor(Color.accent)
                        } else {
                            rect.foregroundColor(Color.secondaryTxt)
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 15)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            if let currentNote,
                let currentNoteIndex = notes.firstIndex(of: currentNote) {
                let nextNoteIndex = notes.index(after: currentNoteIndex)
                self.currentNote = notes[nextNoteIndex]
            } else {
                currentNote = nil
            }
        }
        .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onEnded({ value in
                if value.translation.width < 0 {
                    showNextAuthor()
                }
                
                if value.translation.width > 0 {
                    showPreviousAuthor()
                }
            }))
        
    }
    
    func handleNotesChanged(to notes: FetchedResults<Event>) {
        Task {
            if notes.isEmpty {
                currentNote = nil
            } else if currentNote == nil {
                currentNote = notes.first
            }
        }
    }
}

struct AuthorStoryView_Previews: PreviewProvider {
    
    static var persistenceController = PersistenceController.preview
    static var previewContext = persistenceController.container.viewContext
    static var relayService = RelayService(persistenceController: persistenceController)
    
    static var emptyPersistenceController = PersistenceController.empty
    static var emptyPreviewContext = emptyPersistenceController.container.viewContext
    static var emptyRelayService = RelayService(persistenceController: emptyPersistenceController)
    
    static var router = Router()
    
    static var currentUser: CurrentUser = {
        let currentUser = CurrentUser()
        currentUser.context = previewContext
        currentUser.relayService = relayService
        currentUser.keyPair = KeyFixture.keyPair
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
        
        let follow = Follow(context: context)
        follow.source = alice
        follow.destination = bob
        
        try! context.save()
    }
    
    static var shortNote: Event {
        let note = Event(context: previewContext)
        note.kind = 1
        note.content = "Hello, world!"
        note.author = alice
        note.identifier = "1"
        return note
    }
    
    static var longNote: Event {
        let note = Event(context: previewContext)
        note.kind = 1
        note.content = .loremIpsum(5)
        note.author = bob
        return note
    }
    
    static var previews: some View {
        NavigationView {
            AuthorStoryView(author: bob, showPreviousAuthor: {}, showNextAuthor: {})
        }
        .environment(\.managedObjectContext, previewContext)
        .environmentObject(relayService)
        .environmentObject(router)
        .onAppear {
            createTestData(in: previewContext)
        }
        .environmentObject(currentUser)
    }
}
