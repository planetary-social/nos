import Logger
import SDWebImageSwiftUI
import SwiftUI

/// A button that's filled entirely with an image and presents an ``ImageViewer`` when tapped.
struct ImageButton: View {
    /// The image to display in the button.
    let url: URL

    /// Whether the image viewer is presented or not.
    @State private var isViewerPresented = false

    /// Whether the image is animated or not.
    /// - Note: We don't know this until it's downloaded, so we start by assuming it's not.
    @State private var isAnimated = false

    /// Whether the image is animating or not.
    @State private var isAnimating = false
    
    /// Whether to show an error view or not.
    @State private var showError = false

    var body: some View {
        if showError {
            BrokenLinkView(url: url)
        } else {
            Button {
                isViewerPresented = true
            } label: {
                ZStack {
                    WebImage(url: url, options: [.scaleDownLargeImages], isAnimating: $isAnimating)
                        .onSuccess { image, _, _ in
                            Task {
                                isAnimated = image.sd_isAnimated
                            }
                        }
                        .onFailure { error in
                            showError = true
                            Log.error(error, "There was an error loading the image.")
                        }
                        .resizable()
                        .scaledToFill()

                    if isAnimated && !isAnimating {
                        gifOverlay
                    }
                }
            }
            .sheet(isPresented: $isViewerPresented) {
                ImageViewer(url: url)
            }
        }
    }

    var gifOverlay: some View {
        Button {
            isAnimating = true
        } label: {
            ZStack {
                Color.clear

                Text("gifButton")
                    .font(.title)
                    .foregroundStyle(Color.primaryTxt)
                    .padding()
                    .background(
                        Circle()
                            .fill(Color.gifButtonBackground)
                    )
            }
        }
    }
}

#Preview("Animated GIF") {
    ImageButton(
        url: URL(
            string: "https://image.nostr.build/c57c2e89841cf992626995271aa40571cdcf925b84af473d148595e577471d79.gif"
        )!
    )
}

#Preview("Animated WebP") {
    ImageButton(
        url: URL(
            string: "https://media3.giphy.com/media/v1.Y2lkPTc5MGI3NjExYWtidXM3bTc5bWRzMW15c2xma3ZodXhuOGYzcThzZzB1enh0Z2hhZCZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/iemgeDQlYlgNZrZUoQ/giphy.webp" // swiftlint:disable:this line_length
        )!
    )
}

#Preview("Portrait image") {
    ImageButton(
        url: URL(
            string: "https://images.unsplash.com/photo-1723451119471-dff8dd414e80"
        )!
    )
}

#Preview("Square image") {
    ImageButton(
        url: URL(
            string: "https://image.nostr.build/9640e78f03afc4927d80a15fd1c4bd1404dc654a8663efb92cc9ee1b8b0719a3.jpg"
        )!
    )
}

#Preview("Broken link") {
    ImageButton(
        url: URL(
            string: "https://example.com/foo.jpg"
        )!
    )
}
