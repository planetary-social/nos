import Dependencies
import SwiftUI

/// Presents an overview of the reply activity for the specified note, utilizing various
/// styles listed in `RepliesDisplayType`.
struct RepliesLabel: View {

    @FetchRequest private var replies: FetchedResults<Event>
    @Dependency(\.currentUser) private var currentUser
    @State private var avatars = [URL?]()
    @State private var cachedAttributedReplies: AttributedString?
    
    let repliesDisplayType: RepliesDisplayType
    let noteIdentifier: RawEventID

    init(repliesDisplayType: RepliesDisplayType, for noteIdentifier: RawEventID) {
        self.repliesDisplayType = repliesDisplayType
        self.noteIdentifier = noteIdentifier
        _replies = FetchRequest(fetchRequest: Event.replies(to: noteIdentifier))
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
            var attributed = AttributedString(string)
            if let range = attributed.range(of: "\(count)") {
                attributed[range].foregroundColor = .primaryTxt
            }
            return attributed
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

            if let cachedAttributedReplies {
                Text(cachedAttributedReplies)
                    .font(.clarity(.medium, textStyle: .subheadline))
                    .foregroundColor(Color.secondaryTxt)
                    .lineLimit(1)
            }
        }
        .task {
            updateData()
        }
        .onChange(of: replies.count) {
            updateData()
        }
        .onChange(of: avatars.count) {
            updateData()
        }
    }
    
    private func updateData() {
        Task {
            await computeAvatars()
            cachedAttributedReplies = attributedReplies
        }
    }
}
