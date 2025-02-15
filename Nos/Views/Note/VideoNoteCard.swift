import SwiftUI
import AVKit

struct VideoNoteCard: View {
    let note: Event
    let showsActions: Bool
    let showsLikeCount: Bool
    let showsRepostCount: Bool
    let cornerRadius: CGFloat
    let replyAction: ((Event) -> Void)?

    // Provide default values so they're optional when creating a VideoFirstNoteCard.
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
            // If a title tag exists, display it at the top.
            if let title = (note.allTags as? [[String]])?.first(where: { $0[0] == "title" })?[1] {
                Text(title)
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top, 8)
            }
            
            // Extract video metadata from the imeta tags.
            let videoMetaTags = ((note.allTags as? [[String]]) ?? []).filter { $0[0] == "imeta" }
            if !videoMetaTags.isEmpty {
                TabView {
                    ForEach(videoMetaTags, id: \.self) { tag in
                        // Look for the primary video URL by finding a tag string that starts with "url "
                        if let urlString = tag.first(where: { $0.hasPrefix("url ") })?.dropFirst(4),
                           let videoURL = URL(string: String(urlString)) {
                            // Use VideoPlayer to display/play the video.
                            VideoPlayer(player: AVPlayer(url: videoURL))
                                .frame(height: 300) // Adjust this height as needed.
                                .cornerRadius(cornerRadius)
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle())
                .frame(height: 300)
            }
            
            // Display the video's description/content if available.
            if let content = note.content, !content.isEmpty {
                Text(content)
                    .padding()
            }
            
            // If actions are enabled, show the action buttons.
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
