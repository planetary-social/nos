import SDWebImageSwiftUI
import SwiftUI

/// A button that's filled entirely with an image and presents an `ImageViewer` when tapped.
struct ImageButton: View {
    /// The URL of the image to display as the button label.
    let url: URL

    /// Whether the image viewer is presented or not.
    @State private var isViewerPresented = false

    /// The size of the image that was loaded.
    @State private var imageSize: CGSize?

    var body: some View {
        Color.clear
            .aspectRatio(aspectRatio, contentMode: .fit)
            .overlay(
                Button {
                    isViewerPresented = true
                } label: {
                    WebImage(url: url)
                        .onSuccess { image, _, _ in
                            imageSize = image.size
                        }
                        .resizable()
                        .indicator(.activity)
                        .scaledToFill()
                }
            )
            .clipShape(.rect)
            .contentShape(.rect)
            .sheet(isPresented: $isViewerPresented) {
                ImageViewer(url: url)
            }
    }
    
    /// The aspect ratio of the view. If the image is loaded and is taller than wide, this returns 3/4. Otherwise, 4/3.
    var aspectRatio: CGFloat {
        if let imageSize, imageSize.height > imageSize.width {
            return 3 / 4
        } else {
            return 4 / 3
        }
    }
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
