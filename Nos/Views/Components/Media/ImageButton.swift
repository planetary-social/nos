import SDWebImageSwiftUI
import SwiftUI

/// A button that's filled entirely with an image and presents an ``ImageViewer`` when tapped.
struct ImageButton: View {
    /// The image to display in the button.
    let url: URL

    /// Whether the image viewer is presented or not.
    @State private var isViewerPresented = false

    /// Whether the image is animating or not.
    @State private var isAnimating = false

    var body: some View {
        Button {
            isViewerPresented = true
        } label: {
            ZStack {
                WebImage(url: url, isAnimating: $isAnimating)
                    .resizable()
                    .scaledToFill()

                if url.isGIF && !isAnimating {
                    gifOverlay
                }
            }
        }
        .sheet(isPresented: $isViewerPresented) {
            ImageViewer(url: url)
        }
    }

    var gifOverlay: some View {
        Button {
            isAnimating = true
        } label: {
            ZStack {
                Color.clear

                Text(.localizable.gifButton)
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

#Preview("GIF") {
    ImageButton(
        url: URL(
            string: "https://image.nostr.build/c57c2e89841cf992626995271aa40571cdcf925b84af473d148595e577471d79.gif"
        )!
    )
}

#Preview {
    ImageButton(
        url: URL(
            string: "https://images.unsplash.com/photo-1723451119471-dff8dd414e80"
        )!
    )
}

#Preview {
    ImageButton(
        url: URL(
            string: "https://images.unsplash.com/photo-1723160004469-1b34c81272f3"
        )!
    )
}

#Preview {
    ImageButton(
        url: URL(
            string: "https://images.unsplash.com/photo-1715686529501-e097bd9caea7"
        )!
    )
}

#Preview {
    ImageButton(
        url: URL(
            string: "https://image.nostr.build/9640e78f03afc4927d80a15fd1c4bd1404dc654a8663efb92cc9ee1b8b0719a3.jpg"
        )!
    )
}
