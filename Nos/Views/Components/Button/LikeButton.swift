import Dependencies
import Logger
import SwiftUI

struct LikeButton: View {
    
    let note: Event

    /// Indicates whether the number of likes is displayed.
    let showsCount: Bool

    @FetchRequest private var likes: FetchedResults<Event>

    /// Provides instant feedback when the button is tapped, even though the action it performs is async.
    @State private var isLiked = false

    /// Whether a "like" or "delete like" event is currently being published.
    @State private var isPublishing = false

    @Environment(RelayService.self) private var relayService
    @Environment(CurrentUser.self) private var currentUser
    @Environment(\.managedObjectContext) private var viewContext
    @ObservationIgnored @Dependency(\.analytics) private var analytics

    /// Initializes a LikeButton object.
    ///
    /// - Parameter note: The event associated with this Like button.
    /// - Parameter showsCount: Whether the number of likes is displayed. Defaults to `true`.
    init(note: Event, showsCount: Bool = true) {
        self.note = note
        self.showsCount = showsCount
        if let noteID = note.identifier {
            _likes = FetchRequest(fetchRequest: Event.likes(noteID: noteID))
        } else {
            _likes = FetchRequest(fetchRequest: Event.emptyRequest())
        }
    }
    
    var likeCount: Int {
        likes
            .compactMap { $0.eventReferences.lastObject as? EventReference }
            .map { $0.eventId }
            .filter { $0 == note.identifier }
            .count
    }
      
    var currentUserLikesNote: Bool {
        likes
            .filter {
                $0.author?.hexadecimalPublicKey == currentUser.author?.hexadecimalPublicKey
            }
            .compactMap { $0.eventReferences.lastObject as? EventReference }
            .contains(where: { $0.eventId == note.identifier })
    }
    
    var buttonLabel: some View {
        HStack {
            if currentUserLikesNote || isLiked {
                Image.buttonLikeActive
            } else {
                Image.buttonLikeDefault
            }
            if showsCount, likeCount > 0 {
                Text(likeCount.description)
                    .font(.clarity(.medium, textStyle: .subheadline))
                    .foregroundColor(.secondaryTxt)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 12)
    }
    
    var body: some View {
        Button {
            Task {
                await buttonPressed()
            }
        } label: {
            buttonLabel
        }                             
        .disabled(isPublishing)
    }

    private func buttonPressed() async {
        guard !isPublishing else { return }

        if currentUserLikesNote {
            isLiked = false
            await deleteLike()
        } else {
            isLiked = true
            await publishLike()
        }
    }

    private func deleteLike() async {
        isPublishing = true
        defer { isPublishing = false }

        likes
            .filter {
                $0.author?.hexadecimalPublicKey == currentUser.author?.hexadecimalPublicKey
            }
            .compactMap { $0.eventReferences.lastObject as? EventReference }
            .filter { $0.eventId == note.identifier }
            .compactMap { $0.referencingEvent?.identifier }
            .forEach { likeIdentifier in
                Task {
                    await currentUser.publishDelete(for: [likeIdentifier])
                }
            }
    }

    private func publishLike() async {
        isPublishing = true
        defer { isPublishing = false }

        guard let keyPair = currentUser.keyPair else {
            return
        }

        var tags: [[String]] = []
        if let eventReferences = note.eventReferences.array as? [EventReference] {
            // compactMap returns an array of the non-nil results.
            tags += eventReferences.compactMap { event in
                guard let eventId = event.eventId else { return nil }
                return ["e", eventId]
            }
        }

        if let authorReferences = note.authorReferences.array as? [EventReference] {
            tags += authorReferences.compactMap { author in
                guard let eventId = author.eventId else { return nil }
                return ["p", eventId]
            }
        }

        if let id = note.identifier {
            tags.append(["e", id] + note.seenOnRelayURLs)
        }
        if let pubKey = note.author?.publicKey?.hex {
            tags.append(["p", pubKey])
        }

        let jsonEvent = JSONEvent(
            pubKey: keyPair.publicKeyHex,
            kind: .like,
            tags: tags,
            content: "+"
        )

        do {
            try await relayService.publishToAll(event: jsonEvent, signingKey: keyPair, context: viewContext)
            analytics.likedNote()
        } catch {
            Log.info("Error creating event for like")
        }
    }
}
