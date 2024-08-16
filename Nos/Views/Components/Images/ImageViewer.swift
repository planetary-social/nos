import SDWebImageSwiftUI
import SwiftUI

/// A viewer for images. Supports full-screen zoom and panning.
struct ImageViewer: View {
    /// The URL of the image to display.
    let url: URL

    @Environment(\.dismiss) private var dismiss
    
    /// The current zoom scale of the image.
    @State private var scale: CGFloat = 1.0

    /// The offset of the image. This is updated when the user has zoomed and is panning up, down, left, and right.
    @State private var offset: CGSize = .zero

    /// The previous offset of the image.
    /// - SeeAlso: `offset`
    @State private var zoomScale: CGFloat = 1.0

    /// The size of the image. Will be set to a non-zero value when the image has loaded.
    @State private var imageSize: CGSize = .zero
    
    /// The maximum zoom scale for the image.
    private let maxZoomScale: CGFloat = 10.0
    
    /// The minimum zoom scale for the image.
    private let minZoomScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            Color.imageBackground

            GeometryReader { proxy in
                ScrollView(
                    [.vertical, .horizontal],
                    showsIndicators: false
                ) {
                    WebImage(url: url)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .gesture(doubleTapGesture)
                        .frame(width: proxy.size.width * zoomScale)
                        .frame(height: proxy.size.height * zoomScale)
                }
                .defaultScrollAnchor(.center)
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

    func resetImageState() {
        withAnimation(.interactiveSpring()) {
            zoomScale = minZoomScale
        }
    }

    func onImageDoubleTapped(value: TapGesture.Value) {
        if zoomScale == minZoomScale {
            withAnimation(.spring()) {
                zoomScale = 4
            }
        } else {
            resetImageState()
        }
    }

    var doubleTapGesture: some Gesture {
        TapGesture(count: 2)
            .onEnded(onImageDoubleTapped)
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
