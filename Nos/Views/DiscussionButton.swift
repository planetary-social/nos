import SwiftUI

struct DiscussionButton: View {

    var note: Event

    @State private var relaySubscriptions = SubscriptionCancellables()
    @FetchRequest private var replies: FetchedResults<Event>
    @FetchRequest private var repliesFromFollows: FetchedResults<Event>
    @EnvironmentObject private var relayService: RelayService

    init(note: Event, viewer publicKeyHex: String?) {
        self.note = note

        let noteIdentifier = note.identifier ?? ""
        let publicKeyHex = publicKeyHex ?? ""

        let predicate = NSCompoundPredicate(
            andPredicateWithSubpredicates: [
                NSPredicate(format: "kind = 1"),
                NSPredicate(
                    format: "SUBQUERY(eventReferences, $e, $e.referencedEvent.identifier = %@ AND ($e.marker = 'reply' OR $e.marker = 'root')).@count > 0",
                    noteIdentifier,
                    noteIdentifier
                ),
                NSPredicate(format: "deletedOn.@count = 0"),
                NSPredicate(format: "author.muted = false")
            ]
        )

        let fetchRequest = Event.fetchRequest()
        fetchRequest.includesPendingChanges = false
        fetchRequest.includesSubentities = false
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.identifier, ascending: true)]

        fetchRequest.predicate = predicate
        _replies = FetchRequest(fetchRequest: fetchRequest)

        fetchRequest.relationshipKeyPathsForPrefetching = ["author"]
        fetchRequest.predicate = NSCompoundPredicate(
            andPredicateWithSubpredicates: [
                predicate,
                NSPredicate(
                    format: "%@ IN author.followers.source.hexadecimalPublicKey",
                    publicKeyHex
                )
            ]
        )
        _repliesFromFollows = FetchRequest(fetchRequest: fetchRequest)
    }

    private var isBeingDiscussed: Bool {
        !replies.isEmpty
    }

    private var avatars: [URL?] {
        let authors = Set(repliesFromFollows.compactMap { $0.author })
        return authors.map { $0.profilePhotoURL }
    }

    private var attributedReplies: AttributedString? {
        guard isBeingDiscussed else {
            return nil
        }
        if avatars.isEmpty {
            return AttributedString(
                "Join the discussion",
                attributes: AttributeContainer(
                    [NSAttributedString.Key.foregroundColor: UIColor.primaryTxt]
                )
            )
        } else {
            return AttributedString("in discussion")
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            StackedAvatarsView(
                avatarUrls: avatars,
                size: 20,
                border: 0
            )
            .padding(.trailing, 8)

            if let replies = attributedReplies {
                Text(replies)
                    .font(.clarity(.medium, textStyle: .subheadline))
                    .foregroundColor(Color.secondaryTxt)
            }
        }
        .onAppear {
            subscribeToReplies()
        }
        .onDisappear {
            relaySubscriptions.removeAll()
        }
    }

    func subscribeToReplies() {
        Task(priority: .userInitiated) {
            // Close out stale requests
            relaySubscriptions.removeAll()
            relaySubscriptions.append(
                await relayService.requestAReplyFromAnyone(
                    for: note.identifier
                )
            )
            relaySubscriptions.append(
                await relayService.requestFourRepliesFromFollows(
                    for: note.identifier
                )
            )
        }
    }
}
