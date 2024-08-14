import SDWebImageSwiftUI
import SwiftUI

/// A viewer for images. Supports full-screen zoom and panning.
struct ImageViewer: View {
    /// The URL of the image to display.
    let url: URL

    @Environment(\.dismiss) var dismiss

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var imageSize: CGSize = .zero

    private let maxScale: CGFloat = 10.0
    private let minScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            Color.imageBackground

            GeometryReader { geometry in
                WebImage(url: url)
                    .onSuccess { image, _, _ in
                        imageSize = image.size
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(scale)
                    .offset(x: offset.width, y: offset.height)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                withAnimation {
                                    scale = lastScale * value
                                }
                            }
                            .onEnded { value in
                                withAnimation {
                                    let newScale = lastScale * value
                                    if newScale > maxScale {
                                        scale = maxScale
                                    } else if newScale < minScale {
                                        scale = minScale
                                    }

                                    lastScale = scale
                                }
                            }
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                offset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            }
                            .onEnded { _ in
                                lastOffset = offset
                            }
                    )
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .onTapGesture(count: 2) {
                        withAnimation {
                            if scale == minScale {
                                scale = 4.0
                            } else {
                                scale = minScale
                            }
                            lastScale = scale
                        }
                    }
            }
            .ignoresSafeArea()

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
        .ignoresSafeArea()
    }
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
