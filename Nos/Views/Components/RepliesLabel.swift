import Dependencies
import SwiftUI
import Logger

/// Presents an overview of the reply activity for the specified note, utilizing various
/// styles listed in `RepliesDisplayType`.
struct RepliesLabel: View {

    var repliesDisplayType: RepliesDisplayType
    var note: Event

    @FetchRequest private var replies: FetchedResults<Event>
    @Dependency(\.currentUser) var currentUser
    @State private var avatars = [URL?]()
    // Track the last time we computed avatars to avoid excessive computations
    @State private var lastComputationTime = Date.distantPast

    init(repliesDisplayType: RepliesDisplayType, for note: Event) {
        self.note = note
        self.repliesDisplayType = repliesDisplayType

        let noteIdentifier = note.identifier ?? ""
        _replies = FetchRequest(fetchRequest: Event.replies(to: noteIdentifier))
    }

    private var isBeingDiscussed: Bool {
        !replies.isEmpty
    }

    @MainActor
    private func computeAvatars() async {
        // Throttle computations to once per second
        let now = Date()
        let minInterval: TimeInterval = 1.0 // 1 second throttle
        
        guard now.timeIntervalSince(lastComputationTime) >= minInterval else {
            // Skip this computation if it's too soon
            return
        }
        
        // Update last computation time
        lastComputationTime = now
        
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
                    String(localized: "joinTheDiscussion", table: "Reply"),
                    attributes: AttributeContainer(
                        [NSAttributedString.Key.foregroundColor: UIColor.primaryTxt]
                    )
                )
            } else {
                return AttributedString(localized: "inDiscussion", table: "Reply")
            }
        case .count:
            let count = replies.count
            let string = String.localizedStringWithFormat(String(localized: "replies", table: "Reply"), count)
            do {
                var attributed = try AttributedString(markdown: string)
                if let range = attributed.range(of: "\(count)") {
                    attributed[range].foregroundColor = .primaryTxt
                }
                return attributed
            } catch {
                // Log the error for debugging
                Log.error("Error creating AttributedString for replies: \(error)")
                
                // Fallback to a simple AttributedString without markdown
                var attributed = AttributedString(string)
                if let range = attributed.range(of: "\(count)") {
                    attributed[range].foregroundColor = .primaryTxt
                }
                return attributed
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
        .task {
            await computeAvatars()
        }
        .onChange(of: replies.count) {
            Task {
                await computeAvatars()
            }
        }
    }
}
