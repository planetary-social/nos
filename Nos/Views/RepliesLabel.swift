import Dependencies
import SwiftUI

struct RepliesLabel: View {

    var repliesDisplayType: RepliesDisplayType
    var note: Event

    @State private var relaySubscriptions = SubscriptionCancellables()
    @FetchRequest private var replies: FetchedResults<Event>
    @Dependency(\.currentUser) var currentUser
    @EnvironmentObject private var relayService: RelayService
    @State private var avatars = [URL?]()

    init(repliesDisplayType: RepliesDisplayType, for note: Event) {
        self.note = note
        self.repliesDisplayType = repliesDisplayType

        let noteIdentifier = note.identifier ?? ""

        let format = """
            SUBQUERY(
                eventReferences,
                $e,
                $e.referencedEvent.identifier = %@ AND
                    ($e.marker = 'reply' OR $e.marker = 'root')
            ).@count > 0
        """

        let predicate = NSCompoundPredicate(
            andPredicateWithSubpredicates: [
                NSPredicate(format: "kind = 1"),
                NSPredicate(
                    format: format,
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
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \Event.identifier, ascending: true)
        ]

        fetchRequest.predicate = predicate
        fetchRequest.relationshipKeyPathsForPrefetching = ["author"]
        _replies = FetchRequest(fetchRequest: fetchRequest)
    }

    private var isBeingDiscussed: Bool {
        !replies.isEmpty
    }

    @MainActor
    private func computeAvatars() async {
        let limit = 4
        var authors = Set<Author>()
        switch repliesDisplayType {
        case .displayNothing:
            return
        case .discussion:
            guard let socialGraph = currentUser.socialGraph else {
                return
            }
            var iterator = replies.makeIterator()
            while authors.count < limit, let reply = iterator.next() {
                let author = reply.author
                if let author, await socialGraph.follows(author.hexadecimalPublicKey) {
                    authors.insert(author)
                }
            }
        case .count:
            var iterator = replies.makeIterator()
            while authors.count < limit, let reply = iterator.next() {
                let author = reply.author
                if let author, !author.muted {
                    authors.insert(author)
                }
            }
        }
        avatars = authors.map { $0.profilePhotoURL }
    }

    private var attributedReplies: AttributedString? {
        guard isBeingDiscussed else {
            return nil
        }
        switch repliesDisplayType {
        case .displayNothing:
            return AttributedString()
        case .discussion:
            if avatars.isEmpty {
                return AttributedString(
                    String(localized: .reply.joinTheDiscussion),
                    attributes: AttributeContainer(
                        [NSAttributedString.Key.foregroundColor: UIColor.primaryTxt]
                    )
                )
            } else {
                return AttributedString(String(localized: .reply.inDiscussion))
            }
        case .count:
            let count = replies.count
            let string = String(localized: .reply.replies(count))
            do {
                var attributed = try AttributedString(markdown: string)
                if let range = attributed.range(of: "\(count)") {
                    attributed[range].foregroundColor = .primaryTxt
                }
                return attributed
            } catch {
                return nil
            }
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
                    .lineLimit(1)
            }
        }
        .onAppear {
            subscribeToReplies()
        }
        .onDisappear {
            relaySubscriptions.removeAll()
        }
        .task {
            await computeAvatars()
        }
        .onChange(of: replies.count) {
            Task {
                await computeAvatars()
            }
        }
    }

    /// Open relays subscriptions asking one reply from anyone and up to four
    /// replies from follows.
    func subscribeToReplies() {
        Task(priority: .userInitiated) {
            // Close out stale requests
            relaySubscriptions.removeAll()
            relaySubscriptions.append(
                await relayService.requestReplyFromAnyone(
                    for: note.identifier
                )
            )
            relaySubscriptions.append(
                await relayService.requestRepliesFromFollows(
                    for: note.identifier,
                    limit: 4
                )
            )
        }
    }
}
