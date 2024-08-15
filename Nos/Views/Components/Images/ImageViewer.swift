import SDWebImageSwiftUI
import SwiftUI

/// A viewer for images. Supports full-screen zoom and panning.
struct ImageViewer: View {
    /// The URL of the image to display.
    let url: URL

    @Environment(\.dismiss) var dismiss

    @State private var zoomScale: CGFloat = 1.0
    @State private var previousZoomScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var imageSize: CGSize = .zero
    @State private var anchor: UnitPoint = .center

    private let maxZoomScale: CGFloat = 10.0
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
                        .onSuccess { image, _, _ in
                            imageSize = image.size
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .gesture(
                            zoomGesture
                                .simultaneously(with: doubleTapGesture)
                        )
                        .scaleEffect(CGSize(width: 1.0, height: 1.0), anchor: anchor)
                        .frame(width: proxy.size.width * max(minZoomScale, zoomScale))
                        .frame(maxHeight: .infinity)
                }
                .defaultScrollAnchor(anchor)
            }

            ZStack(alignment: .topLeading) {
                Color.clear

                Button(
                    action: {
                        dismiss()
                    },
                    label: {
                        Image(systemName: "xmark")
                            .symbolVariant(.fill.circle)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.buttonCloseForeground, Color.buttonCloseBackground)
                            .font(.title)
                    }
                )
                .padding()
            }
        }
    }

    func resetImageState() {
        withAnimation(.interactiveSpring()) {
            zoomScale = 1
            anchor = .center
        }
    }

    func onImageDoubleTapped(value: TapGesture.Value) {
        if zoomScale == 1 {
            withAnimation(.spring()) {
                zoomScale = 4
            }
        } else {
            resetImageState()
        }
    }

    func onZoomGestureStarted(value: MagnifyGesture.Value) {
        withAnimation(.easeIn(duration: 0.1)) {
            let delta = value.magnification / previousZoomScale
            previousZoomScale = value.magnification
            let zoomDelta = zoomScale * delta
            var minMaxScale = max(minZoomScale, zoomDelta)
            minMaxScale = min(maxZoomScale, minMaxScale)
            zoomScale = minMaxScale
            anchor = value.startAnchor
        }
    }

    func onZoomGestureEnded(value: MagnifyGesture.Value) {
        previousZoomScale = 1
        anchor = value.startAnchor
        if zoomScale <= 1 {
            resetImageState()
        } else if zoomScale > 5 {
            zoomScale = 5
        }
    }

    var zoomGesture: some Gesture {
        MagnifyGesture()
            .onChanged(onZoomGestureStarted)
            .onEnded(onZoomGestureEnded)
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
