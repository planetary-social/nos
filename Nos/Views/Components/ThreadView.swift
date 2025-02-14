import SwiftUI

struct ThreadView: View {
    
    let root: Event

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
                    ($0.eventReferences.lastObject as? EventReference)?.eventId == currentEvent.identifier
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
            NoteButton(
                note: root,
                repliesDisplayType: .count,
                showsLikeCount: true,
                showsRepostCount: true,
                tapAction: { event in
                    router.push(event)
                }
            )
            .padding(.top, 15)

            ForEach(thread) { event in
                VStack {
                    ZStack {
                        Path { path in
                            path.move(to: CGPoint(x: 35, y: -4))
                            path.addLine(to: CGPoint(x: 35, y: 15))
                        }
                        .stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .fill(Color.secondaryTxt)
                        NoteButton(
                            note: event,
                            repliesDisplayType: .count,
                            tapAction: { event in
                                router.push(event)
                            }
                        )
                        .padding(.top, 15)
                    }
                    .readabilityPadding()
                }
            }
        }
    }
}

struct ThreadView_Previews: PreviewProvider {
    static var previewData = PreviewData()
    static var persistenceController = PersistenceController.preview
    static var previewContext = persistenceController.viewContext
    static var router = Router()
    
    static var emptyPersistenceController = PersistenceController.empty
    static var emptyPreviewContext = emptyPersistenceController.viewContext
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
    
    static var previews: some View {
        ThreadView(root: rootNote, allReplies: [replyNote, secondReply])
            .environment(\.managedObjectContext, emptyPreviewContext)
            .environment(emptyRelayService)
            .environmentObject(router)
            .environment(currentUser)
    }
}
