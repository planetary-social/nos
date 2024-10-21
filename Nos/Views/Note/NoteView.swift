import Logger
import SwiftUI
import SwiftUINavigation
import Dependencies

struct NoteView: View {
    @EnvironmentObject private var relayService: RelayService
    @EnvironmentObject private var router: Router
    @Environment(CurrentUser.self) private var currentUser
    @Dependency(\.analytics) private var analytics
    @Dependency(\.persistenceController) private var persistenceController

    @State private var showReplyComposer = false
    
    @State private var relaySubscriptions = SubscriptionCancellables()
    
    @FocusState private var focusTextView: Bool
    @State private var showKeyboardOnAppear: Bool
    
    var repliesRequest: FetchRequest<Event>
    /// All replies
    var replies: FetchedResults<Event> { repliesRequest.wrappedValue }

    /// The authors who are referenced in a note in addition to those who replied to the note, if any.
    @State private var relatedAuthors: [Author] = []
    @State private var directReplies: [Event] = []
    
    func computeDirectReplies() async {
        directReplies = replies.filter { (reply: Event) in
            guard let eventReferences = reply.eventReferences.array as? [EventReference] else {
                return false
            }
            
            let containsRootMarker = eventReferences.contains(where: { (eventReference: EventReference) in
                eventReference.type == .root
            })
            
            let referencesNoteAsRoot = eventReferences.contains(where: { (eventReference: EventReference) in
                eventReference.eventId == note.identifier && eventReference.type == .root
            })
            
            let containsReplyMarker = eventReferences.contains(where: { (eventReference: EventReference) in
                eventReference.type == .reply
            })
            
            let referencesNoteAsReply = eventReferences.contains(where: { (eventReference: EventReference) in
                eventReference.eventId == note.identifier && eventReference.type == .reply
            })
            
            // This is sloppy, but I'm writing it anyway in a rush.
            // TODO: make sure there isn't a #[0] event reference this is referring to
            let referencesNoteTheDeprecatedWay = eventReferences.last?.eventId == note.identifier
            
            return (referencesNoteAsRoot && !containsReplyMarker) ||
                referencesNoteAsReply ||
                (!containsRootMarker && !containsReplyMarker && referencesNoteTheDeprecatedWay)
        }
    }
    
    init(note: Event, showKeyboard: Bool = false) {
        self.note = note
        self.repliesRequest = FetchRequest(fetchRequest: Event.allReplies(to: note))
        _showKeyboardOnAppear = .init(initialValue: showKeyboard)
    }
    
    var note: Event

    /// Retrieves a list of authors associated with the current note, including the
    /// rootNote if any and any author referenced in a note.
    ///
    /// - Returns: An array of `Author` objects.
    private func computeRelatedAuthors() -> [Author] {
        var authors: Set<Author> = []

        // Include the author of the root note
        if let rootNoteAuthor = note.rootNote()?.author {
            authors.insert(rootNoteAuthor)
        }

        // Include the author of the current note
        if let noteAuthor = note.author {
            authors.insert(noteAuthor)
        }

        // Include authors referenced in the current note
        let noteAuthorReferences = note.loadAuthorsFromReferences(in: persistenceController.viewContext)
        authors.formUnion(noteAuthorReferences)

        // Include authors referenced in the root note
        if let rootNoteAuthorReferences = note.rootNote()?.loadAuthorsFromReferences(
            in: persistenceController.viewContext
        ) {
            authors.formUnion(rootNoteAuthorReferences)
        }

        // Include up to 10 authors from direct replies
        let tenDirectReplies = directReplies.compactMap { $0.author }.prefix(10)
        authors.formUnion(tenDirectReplies)

        return Array(authors)
    }

    func subscribeToReplies() {
        Task(priority: .userInitiated) {
            // Close out stale requests
            relaySubscriptions.removeAll()
            
            let eTags = ([note.identifier] + replies.map { $0.identifier }).compactMap { $0 }
            let filter = Filter(
                kinds: [.text, .like, .delete, .repost, .report, .label],
                eTags: eTags,
                keepSubscriptionOpen: true
            )
            let subIDs = await relayService.fetchEvents(matching: filter)
            relaySubscriptions.append(subIDs)
            
            // download reports for this user and the replies' authors
            guard let authorKey = note.author?.hexadecimalPublicKey else {
                return
            }
            let pTags = Array(Set([authorKey] + replies.compactMap { $0.author?.hexadecimalPublicKey }))
            let reportFilter = Filter(
                kinds: [.report],
                pTags: pTags,
                keepSubscriptionOpen: true
            )
            relaySubscriptions.append(
                await relayService.fetchEvents(matching: reportFilter)
            )
        }
    }
    
    var body: some View {
        GeometryReader { _ in
            VStack {
                ScrollView(.vertical) {
                    LazyVStack {
                        NoteButton(
                            note: note,
                            shouldTruncate: false,
                            hideOutOfNetwork: false,
                            displayRootMessage: true,
                            isTapEnabled: false,
                            replyAction: { _ in self.showReplyComposer = true },
                            tapAction: { tappedEvent in tappedEvent.referencedNote().unwrap { router.push($0) } }
                        )
                        .padding(.top, 15)
                        .sheet(isPresented: $showReplyComposer, content: {
                            NoteComposer(
                                replyTo: note,
                                relatedAuthors: relatedAuthors,
                                isPresented: $showReplyComposer
                            )
                                .environment(currentUser)
                                .interactiveDismissDisabled()
                        })
                        .onChange(of: showReplyComposer) { _, newValue in
                            if newValue {
                                relatedAuthors = computeRelatedAuthors()
                            }
                        }

                        ForEach(directReplies.reversed()) { event in
                            ThreadView(root: event, allReplies: replies.reversed())
                        }
                    }
                    .padding(.bottom)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 1)
                .nosNavigationBar("thread")
                .onAppear {
                    subscribeToReplies()
                }
                .refreshable {
                    subscribeToReplies()
                }
                .onDisappear {
                    relaySubscriptions.removeAll()
                }
                .onAppear {
                    Task { @MainActor in
                        try await Task.sleep(for: .milliseconds(300))
                        if showKeyboardOnAppear {
                            showReplyComposer = true
                            showKeyboardOnAppear = false
                        }
                    }
                    analytics.showedThread()
                }
                Spacer()
            }
            .background(Color.appBg)
            .toolbar {
                if focusTextView {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            focusTextView = false
                        }, label: {
                            Text("cancel")
                                .foregroundColor(.primaryTxt)
                        })
                    }
                }
            }
            .task {
                await computeDirectReplies()
            }
            .onChange(of: replies.count) { 
                Task {
                    await computeDirectReplies()
                }
            }
        }
    }
}
struct RepliesView_Previews: PreviewProvider {
    
    static var previewData = PreviewData(currentUserKey: KeyFixture.alice)
    static var persistenceController = PersistenceController.preview
    static var previewContext = persistenceController.viewContext
    static var emptyRelayService = previewData.relayService
    static var router = Router()
    static var currentUser = previewData.currentUser
    
    static var shortNote: Event {
        let note = Event(context: previewContext)
        note.kind = 1
        note.createdAt = .now
        note.content = "Hello, world!"
        note.author = user
        return note
    }
    
    static var longNote: Event {
        let note = Event(context: previewContext)
        note.kind = 1
        note.createdAt = .now
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
        Group {
            VStack {
                NoteView(note: shortNote)
            }
            VStack {
                NoteView(note: longNote)
            }
        }
        .environment(\.managedObjectContext, previewContext)
        .environmentObject(emptyRelayService)
        .environmentObject(router)
        .environment(currentUser)
        .padding()
        .background(Color.previewBg)
    }
}
