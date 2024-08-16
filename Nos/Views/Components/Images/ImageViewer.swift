import SDWebImageSwiftUI
import SwiftUI

/// A viewer for images. Supports full-screen zoom and panning.
struct ImageViewer: View {
    /// The URL of the image to display.
    let url: URL

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.imageBackground

            ZoomableContainer {
                WebImage(url: url)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }

            ZStack(alignment: .topLeading) {
                Color.clear

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .symbolVariant(.fill.circle)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(Color.buttonCloseForeground, Color.buttonCloseBackground)
                        .font(.title)
                }
                .padding()
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    ImageViewer(
        url: URL(
            string: "https://image.nostr.build/92d0ed5e3c53fa33e379f0982d52058f0dde98f0c287669fd1e7c5b4b86b5dbb.jpg"
        )!
    )
}

#Preview {
    ImageViewer(
        url: URL(
            string: "https://images.unsplash.com/photo-1715686529501-e097bd9caea7"
        )!
    )
}

#Preview {
    ImageViewer(
        url: URL(
            string: "https://images.unsplash.com/photo-1723160004469-1b34c81272f3"
        )!
    )
}

#Preview {
    ImageViewer(
        url: URL(
            string: "https://image.nostr.build/9640e78f03afc4927d80a15fd1c4bd1404dc654a8663efb92cc9ee1b8b0719a3.jpg"
        )!
    )
}

#Preview {
    ImageViewer(
        url: URL(
            string: "https://images.unsplash.com/photo-1716783841007-7de314270444"
        )!
    )
}
