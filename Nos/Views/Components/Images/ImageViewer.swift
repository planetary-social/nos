import SDWebImageSwiftUI
import SwiftUI

/// A viewer for images. Supports full-screen zoom and panning.
struct ImageViewer: View {
    /// The URL of the image to display.
    let url: URL

    @Environment(\.dismiss) var dismiss

    @State private var zoomScale: CGFloat = 1.0

    private let maxZoomScale: CGFloat = 10.0
    private let minZoomScale: CGFloat = 1.0

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

fileprivate let maxAllowedScale = 4.0

struct ZoomableContainer<ContainerContent: View>: View {
    let content: ContainerContent

    @State private var currentScale: CGFloat = 1.0
    @State private var tapLocation: CGPoint = .zero

    init(@ViewBuilder content: () -> ContainerContent) {
        self.content = content()
    }

    func doubleTapAction(location: CGPoint) {
        tapLocation = location
        currentScale = currentScale == 1.0 ? maxAllowedScale : 1.0
    }

    var body: some View {
        ZoomableScrollView(scale: $currentScale, tapLocation: $tapLocation) {
            content
        }
        .onTapGesture(count: 2, perform: doubleTapAction)
    }

    fileprivate struct ZoomableScrollView<ScrollViewContent: View>: UIViewRepresentable {
        private var content: ScrollViewContent
        @Binding private var currentScale: CGFloat
        @Binding private var tapLocation: CGPoint

        init(scale: Binding<CGFloat>, tapLocation: Binding<CGPoint>, @ViewBuilder content: () -> ScrollViewContent) {
            _currentScale = scale
            _tapLocation = tapLocation
            self.content = content()
        }

        func makeUIView(context: Context) -> UIScrollView {
            // Setup the UIScrollView
            let scrollView = UIScrollView()
            scrollView.delegate = context.coordinator // for viewForZooming(in:)
            scrollView.maximumZoomScale = maxAllowedScale
            scrollView.minimumZoomScale = 1
            scrollView.bouncesZoom = true
            scrollView.showsHorizontalScrollIndicator = false
            scrollView.showsVerticalScrollIndicator = false
            scrollView.clipsToBounds = false

            // Create a UIHostingController to hold our SwiftUI content
            let hostedView = context.coordinator.hostingController.view!
            hostedView.translatesAutoresizingMaskIntoConstraints = true
            hostedView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            hostedView.frame = scrollView.bounds
            hostedView.backgroundColor = .clear
            scrollView.addSubview(hostedView)

            return scrollView
        }

        func makeCoordinator() -> Coordinator {
            Coordinator(hostingController: UIHostingController(rootView: content), scale: $currentScale)
        }

        func updateUIView(_ uiView: UIScrollView, context: Context) {
            // Update the hosting controller's SwiftUI content
            context.coordinator.hostingController.rootView = content

            if uiView.zoomScale > uiView.minimumZoomScale { // Scale out
                uiView.setZoomScale(currentScale, animated: true)
            } else if tapLocation != .zero { // Scale in to a specific point
                uiView.zoom(to: zoomRect(for: uiView, scale: uiView.maximumZoomScale, center: tapLocation), animated: true)
                // Reset the location to prevent scaling to it in case of a negative scale (manual pinch)
                // Use the main thread to prevent unexpected behavior
                DispatchQueue.main.async { tapLocation = .zero }
            }

            assert(context.coordinator.hostingController.view.superview == uiView)
        }

        // MARK: - Utils

        func zoomRect(for scrollView: UIScrollView, scale: CGFloat, center: CGPoint) -> CGRect {
            let scrollViewSize = scrollView.bounds.size

            let width = scrollViewSize.width / scale
            let height = scrollViewSize.height / scale
            let xPosition = center.x - (width / 2.0)
            let yPosition = center.y - (height / 2.0)

            return CGRect(x: xPosition, y: yPosition, width: width, height: height)
        }

        // MARK: - Coordinator

        class Coordinator: NSObject, UIScrollViewDelegate {
            var hostingController: UIHostingController<ScrollViewContent>
            @Binding var currentScale: CGFloat

            init(hostingController: UIHostingController<ScrollViewContent>, scale: Binding<CGFloat>) {
                self.hostingController = hostingController
                _currentScale = scale
            }

            func viewForZooming(in scrollView: UIScrollView) -> UIView? {
                hostingController.view
            }

            func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
                currentScale = scale
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
