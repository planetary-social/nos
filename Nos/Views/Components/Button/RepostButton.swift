import SwiftUI
import SwiftUINavigation
import Logger

struct RepostButton: View {
    
    let note: Event

    /// Indicates whether the number of reposts is displayed.
    let showsCount: Bool

    @FetchRequest private var reposts: FetchedResults<Event>
    @Environment(RelayService.self) private var relayService
    @Environment(CurrentUser.self) private var currentUser
    @Environment(\.managedObjectContext) private var viewContext
    
    /// We use this to give instant feedback when the button is tapped, even though the action it performs is async.
    @State private var tapped = false
    @State private var shouldConfirmRepost = false
    @State private var shouldConfirmDelete = false
    @State private var showQuotedNoteComposer = false
    
    /// Initializes a RepostButton object.
    ///
    /// - Parameter note: Note event to display reposts to.
    /// - Parameter showsCount: Whether the number of reposts is displayed. Defaults to `true`.
    init(note: Event, showsCount: Bool = true) {
        self.note = note
        self.showsCount = showsCount
        _reposts = FetchRequest(fetchRequest: Event.reposts(noteID: note.identifier ?? ""))
    }
    
    var currentUserRepostedNote: Bool {
        reposts.contains {
            $0.author?.hexadecimalPublicKey == currentUser.author?.hexadecimalPublicKey
        }
    }

    var body: some View {
        Button { 
            Task {
                await buttonPressed()
            }
        } label: {
            HStack {
                if currentUserRepostedNote || tapped {
                    Image.repostButtonPressed
                } else {
                    Image.repostButton
                }
                
                if showsCount, reposts.count > 0 {
                    Text(reposts.count.description)
                        .font(.clarity(.medium, textStyle: .subheadline))
                        .foregroundColor(.secondaryTxt)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 12)
        }
        .disabled(tapped)
        .confirmationDialog("repost", isPresented: $shouldConfirmRepost) {
            Button("repost") {
                Task { await repostNote() }
            }
            Button("quote") {
                showQuotedNoteComposer = true
            }
            Button("cancel", role: .cancel) {
                tapped = false
            }
        }
        .confirmationDialog("deleteRepost", isPresented: $shouldConfirmDelete) {
            Button("deleteRepost", role: .destructive) {
                Task { await deleteReposts() }
            }
        }
        .sheet(isPresented: $showQuotedNoteComposer) {
            NoteComposer(quotedNoteID: note.identifier, isPresented: $showQuotedNoteComposer)
                .environment(currentUser)
                .interactiveDismissDisabled()
                .onDisappear {
                    tapped = false
                }
        }
    }
    
    func buttonPressed() async {
        if !tapped && !currentUserRepostedNote {
            tapped = true
            shouldConfirmRepost = true
        } else if !tapped && currentUserRepostedNote {
            shouldConfirmDelete = true
        } else {
            // The repost is currently being published, don't do anything.
        }
    }
    
    func repostNote() async {
        defer { tapped = false }
        guard let keyPair = currentUser.keyPair else {
            return
        }
        
        var tags: [[String]] = []
        if let id = note.identifier {
            tags.append(["e", id] + note.seenOnRelayURLs)
        }
        if let pubKey = note.author?.publicKey?.hex {
            tags.append(["p", pubKey])
        }
        
        let jsonEvent = JSONEvent(
            pubKey: keyPair.publicKeyHex,
            kind: .repost,
            tags: tags,
            content: note.jsonString ?? ""
        )
        
        do {
            try await relayService.publishToAll(event: jsonEvent, signingKey: keyPair, context: viewContext)
        } catch {
            Log.error(error, "Error creating event for repost")
        }
    }
    
    func deleteReposts() async {
        reposts
            .filter {
                $0.author?.hexadecimalPublicKey == currentUser.author?.hexadecimalPublicKey
            }
            .compactMap { $0.identifier }
            .forEach { noteIdentifier in
                Task {
                    await currentUser.publishDelete(for: [noteIdentifier])
                }
            }
    }
}
