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
                        DragGesture()
                            .onChanged { value in
                                withAnimation {
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                            }
                            .onEnded { value in
                                withAnimation {
                                    // scaledImageWidth is only the geometry width * scale if the image ratio of
                                    // width to height is greater than the device ratio of width to height
                                    let imageRatio = imageSize.width / imageSize.height
                                    let geometryRatio = geometry.size.width / geometry.size.height
                                    if imageRatio > geometryRatio {
                                        let scaledImageWidth = geometry.size.width * scale
                                        let horizontalPanningRange = scaledImageWidth - geometry.size.width
                                        let maxWidthOffset = horizontalPanningRange / 2
                                        let minWidthOffset = -maxWidthOffset

                                        if offset.width < minWidthOffset {
                                            offset.width = minWidthOffset
                                        } else if offset.width > maxWidthOffset {
                                            offset.width = maxWidthOffset
                                        }

                                        // TODO: figure out the min and max height offset when zoomed
                                        if scale == 1 {
                                            offset.height = 0
                                        }
                                    } else {
                                        let scaledImageHeight = geometry.size.height * scale
                                        let verticalPanningRange = scaledImageHeight - geometry.size.height
                                        let maxHeightOffset = verticalPanningRange / 2
                                        let minHeightOffset = -maxHeightOffset

                                        if offset.height < minHeightOffset {
                                            offset.height = minHeightOffset
                                        } else if offset.height > maxHeightOffset {
                                            offset.height = maxHeightOffset
                                        }

                                        // TODO: figure out the min and max width offset when zoomed
                                        if scale == 1 {
                                            offset.width = 0
                                        }
                                    }

                                    lastOffset = offset
                                }
                            }
                            .simultaneously(
                                with: MagnificationGesture()
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
                    )
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .onTapGesture(count: 2) {
                        withAnimation {
                            if scale == minScale {
                                scale = 4.0
                            } else {
                                scale = minScale
                                offset.width = 0
                                offset.height = 0
                                lastOffset = offset
                            }
                            lastScale = scale
                        }
                    }
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