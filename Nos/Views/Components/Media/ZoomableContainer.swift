import SwiftUI

/// A container that allows its content to be zoomed.
/// - Note: Thanks, [Ido](https://stackoverflow.com/users/8157190/ido) for your
///         [answer](https://stackoverflow.com/a/76649224) on StackOverflow!
struct ZoomableContainer<ContainerContent: View>: View {
    let content: ContainerContent
    private let maxAllowedScale = 4.0

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
        ZoomableScrollView(maxAllowedScale: maxAllowedScale, scale: $currentScale, tapLocation: $tapLocation) {
            content
        }
        .onTapGesture(count: 2, perform: doubleTapAction)
    }
}

fileprivate struct ZoomableScrollView<ScrollViewContent: View>: UIViewRepresentable {
    private let content: ScrollViewContent
    private let maxAllowedScale: CGFloat

    @Binding private var currentScale: CGFloat
    @Binding private var tapLocation: CGPoint

    init(
        maxAllowedScale: CGFloat,
        scale: Binding<CGFloat>,
        tapLocation: Binding<CGPoint>,
        @ViewBuilder content: () -> ScrollViewContent
    ) {
        self.maxAllowedScale = maxAllowedScale
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
