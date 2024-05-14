import Logger
import SwiftUI
import SwiftUINavigation
import Dependencies

struct ReplyToNavigationDestination: Hashable {
    var note: Event
}

struct RepliesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @EnvironmentObject private var relayService: RelayService
    @EnvironmentObject private var router: Router
    @Environment(CurrentUser.self) private var currentUser
    @Dependency(\.analytics) private var analytics

    @State private var reply = EditableNoteText()
    
    @State private var alert: AlertState<Never>?
    @State private var showReplyComposer = false
    
    @State private var relaySubscriptions = SubscriptionCancellables()
    
    @FocusState private var focusTextView: Bool
    @State private var showKeyboardOnAppear: Bool
    
    var repliesRequest: FetchRequest<Event>
    /// All replies
    var replies: FetchedResults<Event> { repliesRequest.wrappedValue }
  
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
    
    func subscribeToReplies() {
        Task(priority: .userInitiated) {
            // Close out stale requests
            relaySubscriptions.removeAll()
            
            let eTags = ([note.identifier] + replies.map { $0.identifier }).compactMap { $0 }
            let filter = Filter(kinds: [.text, .like, .delete, .repost, .report, .label], eTags: eTags)
            let subIDs = await relayService.subscribeToEvents(matching: filter)
            relaySubscriptions.append(subIDs)
            
            // download reports for this user and the replies' authors
            guard let authorKey = note.author?.hexadecimalPublicKey else {
                return
            }
            let pTags = Array(Set([authorKey] + replies.compactMap { $0.author?.hexadecimalPublicKey }))
            let reportFilter = Filter(kinds: [.report], pTags: pTags)
            relaySubscriptions.append(await relayService.subscribeToEvents(matching: reportFilter))
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
                            showReplyCount: false,
                            displayRootMessage: true,
                            isTapEnabled: false,
                            replyAction: { _ in self.showReplyComposer = true },
                            tapAction: { tappedEvent in tappedEvent.referencedNote().unwrap { router.push($0) } }
                        )
                        .padding(.top, 15)
                        .sheet(isPresented: $showReplyComposer, content: {
                            NewNoteView(replyTo: note, isPresented: $showReplyComposer)
                                .environment(currentUser)
                        })
                        
                        ForEach(directReplies.reversed()) { event in
                            ThreadView(root: event, allReplies: replies.reversed())
                        }
                    }
                    .padding(.bottom)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 1)
                .nosNavigationBar(title: .localizable.thread)
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
                            Text(.localizable.cancel)
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
    
    static var previewData = PreviewData()
    static var persistenceController = {
        let persistenceController = PersistenceController.preview
        KeyChain.save(key: KeyChain.keychainPrivateKey, data: Data(KeyFixture.alice.privateKeyHex.utf8))
        return persistenceController
    }()
    static var previewContext = persistenceController.container.viewContext
    static var emptyPersistenceController = PersistenceController.empty
    static var emptyPreviewContext = emptyPersistenceController.container.viewContext
    static var emptyRelayService = previewData.relayService
    static var relayService = previewData.relayService
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
                RepliesView(note: shortNote)
            }
            VStack {
                RepliesView(note: longNote)
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
