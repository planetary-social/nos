import SwiftUI
import AVKit

struct VideoNoteCard: View {
    let note: Event
    let showsActions: Bool
    let showsLikeCount: Bool
    let showsRepostCount: Bool
    let cornerRadius: CGFloat
    let replyAction: ((Event) -> Void)?

    // Provide default values so they're optional when creating a VideoNoteCard.
    init(note: Event,
         showsActions: Bool = false,
         showsLikeCount: Bool = false,
         showsRepostCount: Bool = false,
         cornerRadius: CGFloat,
         replyAction: ((Event) -> Void)? = nil) {
        
        // Simplified initialization using tuple assignment
        (self.note, self.showsActions, self.showsLikeCount,
         self.showsRepostCount, self.cornerRadius, self.replyAction) =
        (note, showsActions, showsLikeCount,
         showsRepostCount, cornerRadius, replyAction)
    }

    var body: some View {
        VStack(spacing: 0) {
            // If a title tag exists, display it at the top.
            if let title = note.getTagValue(key: "title") {
                Text(title)
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top, 8)
            }
            
            // Extract video metadata from the imeta tags.
            let videoMetaTags = note.getMediaMetaTags()
            if !videoMetaTags.isEmpty {
                TabView {
                    ForEach(videoMetaTags, id: \.self) { tag in
                        // Use helper method to get the URL
                        if let videoURL = note.getURLFromTag(tag) {
                            // Use VideoPlayer to display/play the video with a better loading experience
                            ZStack {
                                VideoPlayer(player: AVPlayer(url: videoURL))
                                    .frame(height: 300)
                                    .cornerRadius(cornerRadius)
                                    .overlay(
                                        // Show loading indicator until video loads
                                        Rectangle()
                                            .fill(Color.clear)
                                            .background(
                                                ProgressView()
                                                    .scaleEffect(1.5)
                                                    .progressViewStyle(CircularProgressViewStyle())
                                            )
                                            .opacity(0.5)
                                            .allowsHitTesting(false)
                                    )
                            }
                        } else {
                            // Fallback if video URL is invalid or missing
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 300)
                                .cornerRadius(cornerRadius)
                                .overlay(
                                    VStack(spacing: 12) {
                                        Image(systemName: "video.slash")
                                            .font(.largeTitle)
                                            .foregroundColor(.secondary)
                                        Text("Video unavailable")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                )
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
