import SwiftUI
struct PictureFirstNoteCard: View {
    let note: Event
    let showsActions: Bool
    let showsLikeCount: Bool
    let showsRepostCount: Bool
    let cornerRadius: CGFloat
    let replyAction: ((Event) -> Void)?

    // Provide default values here so they're optional parameters when creating a PictureFirstNoteCard.
    init(note: Event,
        showsActions: Bool = false,
        showsLikeCount: Bool = false,
        showsRepostCount: Bool = false,
        cornerRadius: CGFloat,
        replyAction: ((Event) -> Void)? = nil) {
        self.note = note
        self.showsActions = showsActions
        self.showsLikeCount = showsLikeCount
        self.showsRepostCount = showsRepostCount
        self.cornerRadius = cornerRadius
        self.replyAction = replyAction
    }

    var body: some View {
        VStack(spacing: 0) {
            if let title = (note.allTags as? [[String]])?.first(where: { $0[0] == "title" })?[1] {
                Text(title)
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top, 8)
            }
            let imageMetaTags = ((note.allTags as? [[String]]) ?? []).filter { $0[0] == "imeta" }
            if !imageMetaTags.isEmpty {
                TabView {
                    ForEach(imageMetaTags, id: \.self) { tag in
                        if let url = tag.first(where: { $0.hasPrefix("url ") })?.dropFirst(4) {
                            AsyncImage(url: URL(string: String(url))) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            } placeholder: {
                                ProgressView()
                            }
                            .padding(.vertical)
                        }
                    }
                }
                .tabViewStyle(.page)
                .frame(height: 300)
            }
            if let content = note.content, !content.isEmpty {
                Text(content)
                    .padding()
            }
            if showsActions {
                BeveledSeparator()
                HStack(spacing: 0) {
                    Spacer()
                    RepostButton(note: note, showsCount: showsRepostCount)
                    LikeButton(note: note, showsCount: showsLikeCount)
                    ReplyButton(note: note, replyAction: replyAction)
                }
                .padding(.horizontal, 5)
                .padding(.vertical, 5)
            }
        }
        .background(
            LinearGradient.cardBackground
                .cornerRadius(cornerRadius)
        )
    }
}
