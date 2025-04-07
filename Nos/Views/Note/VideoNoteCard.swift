import SwiftUI
import AVKit
import Logger

struct VideoNoteCard: View {
    let note: Event
    let showsActions: Bool
    let showsLikeCount: Bool
    let showsRepostCount: Bool
    let cornerRadius: CGFloat
    let replyAction: ((Event) -> Void)?
    
    // Create a StateObject for each AVPlayer to keep it alive for the view's lifetime
    @StateObject private var playerViewModel = VideoPlayerViewModel()
    
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
    
    // ViewModel to manage AVPlayer lifecycle
    class VideoPlayerViewModel: ObservableObject {
        @Published var isLoading = true
        @Published var player: AVPlayer?
        @Published var error: Error?
        
        // Track attempts to avoid infinite retry loops
        private var attemptCount = 0
        private let maxAttempts = 3
        
        func loadPlayer(with url: URL) {
            isLoading = true
            error = nil
            
            // Increment attempt counter
            attemptCount += 1
            
            // Check if we've hit the retry limit
            guard attemptCount <= maxAttempts else {
                Log.error("Exceeded maximum retry attempts for video: \(url)")
                self.error = NSError(domain: "VideoPlayerError", code: 2, 
                                   userInfo: [NSLocalizedDescriptionKey: "Too many failed attempts"])
                self.isLoading = false
                return
            }
            
            // Log the URL we're trying to load
            Log.debug("Attempting to load video from URL: \(url), attempt \(attemptCount)")
            
            // Create an asset and check if it's playable
            let asset = AVAsset(url: url)
            
            // Create a player item to better monitor loading state
            let playerItem = AVPlayerItem(asset: asset)
            
            // Create player with player item
            let player = AVPlayer(playerItem: playerItem)
            
            // Set up observation of player item status
            let statusObservation = playerItem.observe(\.status, options: [.new]) { [weak self] item, _ in
                guard let self = self else { return }
                
                Task { @MainActor in
                    switch item.status {
                    case .readyToPlay:
                        Log.debug("Video is ready to play: \(url)")
                        self.player = player
                        self.isLoading = false
                    case .failed:
                        if let error = item.error {
                            Log.error("Error loading video: \(error.localizedDescription)")
                            self.error = error
                        } else {
                            Log.error("Unknown error loading video")
                            self.error = NSError(domain: "VideoPlayerError", code: 1, 
                                               userInfo: [NSLocalizedDescriptionKey: "Failed to load video"])
                        }
                        self.isLoading = false
                    case .unknown:
                        // Still loading, keep waiting
                        break
                    @unknown default:
                        Log.error("Unknown player item status")
                        self.error = NSError(domain: "VideoPlayerError", code: 3, 
                                           userInfo: [NSLocalizedDescriptionKey: "Unknown player status"])
                        self.isLoading = false
                    }
                }
            }
            
            // Set up error observation
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemFailedToPlayToEndTime,
                object: playerItem,
                queue: .main
            ) { [weak self] notification in
                guard let self = self,
                      let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error else {
                    return
                }
                
                Log.error("Failed to play to end: \(error.localizedDescription)")
                self.error = error
                self.isLoading = false
            }
            
            // Store these to prevent them from being deallocated
            objc_setAssociatedObject(player, "statusObservation", statusObservation, .OBJC_ASSOCIATION_RETAIN)
            
            // Preload some content
            player.automaticallyWaitsToMinimizeStalling = true
            player.preroll(atRate: 1.0) { [weak self] success in
                guard let self = self else { return }
                
                Task { @MainActor in
                    if !success {
                        Log.error("Failed to preroll video: \(url)")
                        if self.player == nil && self.error == nil {
                            self.error = NSError(domain: "VideoPlayerError", code: 4, 
                                               userInfo: [NSLocalizedDescriptionKey: "Failed to preroll video"])
                            self.isLoading = false
                        }
                    }
                }
            }
        }
        
        // Reset the view model for reuse
        func reset() {
            player?.pause()
            player = nil
            error = nil
            isLoading = true
            attemptCount = 0
        }
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
            let allMediaTags = note.getMediaMetaTags()
            
            // Filter for video-specific tags
            let videoTags = allMediaTags.filter { note.isVideoTag($0) }
            
            // If we have video tags, display them
            if !videoTags.isEmpty {
                TabView {
                    ForEach(videoTags, id: \.self) { tag in
                        // Use helper method to get the URL
                        if let videoURL = note.getURLFromTag(tag) {
                            VideoPlayerView(url: videoURL, viewModel: playerViewModel, cornerRadius: cornerRadius)
                                .frame(height: 300)
                                .onAppear {
                                    Log.debug("Video tag found with URL: \(videoURL)")
                                    // Reset the view model when switching between videos
                                    playerViewModel.reset()
                                    // Load the player when this view appears
                                    playerViewModel.loadPlayer(with: videoURL)
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
                                        Text("Video URL missing")
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
            // As a fallback, if we have media tags but none were identified as videos, try them anyway
            else if !allMediaTags.isEmpty {
                TabView {
                    ForEach(allMediaTags, id: \.self) { tag in
                        if let mediaURL = note.getURLFromTag(tag) {
                            VStack {
                                VideoPlayerView(url: mediaURL, viewModel: playerViewModel, cornerRadius: cornerRadius)
                                    .frame(height: 300)
                                    .onAppear {
                                        Log.debug("Attempting to play media URL as video: \(mediaURL)")
                                        // Reset when switching between media
                                        playerViewModel.reset()
                                        playerViewModel.loadPlayer(with: mediaURL)
                                    }
                                
                                if let mimeType = note.getMimeType(from: tag) {
                                    Text("Media type: \(mimeType)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        } else {
                            // Fallback if media URL is invalid or missing
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 300)
                                .cornerRadius(cornerRadius)
                                .overlay(
                                    VStack(spacing: 12) {
                                        Image(systemName: "exclamationmark.triangle")
                                            .font(.largeTitle)
                                            .foregroundColor(.secondary)
                                        Text("Media URL missing")
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

// Custom view to handle different states of the video player
struct VideoPlayerView: View {
    let url: URL
    @ObservedObject var viewModel: VideoNoteCard.VideoPlayerViewModel
    let cornerRadius: CGFloat
    
    var body: some View {
        ZStack {
            if let player = viewModel.player {
                // Player is available, show the video
                VideoPlayer(player: player)
                    .cornerRadius(cornerRadius)
                    .onDisappear {
                        // Pause the player when view disappears to save resources
                        player.pause()
                    }
                    .onAppear {
                        // Autoplay doesn't always work, so force play here
                        player.play()
                    }
                    // Add tap gesture to play/pause
                    .overlay(
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if player.timeControlStatus == .playing {
                                    player.pause()
                                } else {
                                    player.play()
                                }
                            }
                    )
                    // Show play/pause icon overlay
                    .overlay(
                        Image(systemName: player.timeControlStatus == .playing ? "pause.circle" : "play.circle")
                            .font(.system(size: 42))
                            .foregroundColor(.white.opacity(0.7))
                            .shadow(radius: 2)
                            .padding()
                            .opacity(0.7)
                    )
            } else if let error = viewModel.error {
                // Error loading video, show error state
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .cornerRadius(cornerRadius)
                    .overlay(
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.largeTitle)
                                .foregroundColor(.orange)
                            
                            if let nsError = error as? NSError {
                                Text(nsError.localizedDescription)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            } else {
                                Text("Error loading video")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Button("Retry") {
                                viewModel.reset()
                                viewModel.loadPlayer(with: url)
                            }
                            .padding(6)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            
                            // Option to open in external player
                            Button("Open in Browser") {
                                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                            }
                            .padding(6)
                            .background(Color.secondary)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                    )
            } else {
                // Loading state
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .cornerRadius(cornerRadius)
                    .overlay(
                        VStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .progressViewStyle(CircularProgressViewStyle())
                            Text("Loading video...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(url.lastPathComponent)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    )
            }
        }
        .transition(.opacity)
        .animation(.easeInOut, value: viewModel.isLoading)
        .animation(.easeInOut, value: viewModel.error != nil)
    }
}
