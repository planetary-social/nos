import Dependencies
import SwiftUI

/// Displays an array of URLs in a tab view with custom paging indicators.
/// If only one URL is provided, displays a ``LinkView`` with the URL.
struct GalleryView: View {
    /// The URLs of the content to display.
    let urls: [URL]
    
    /// The currently-selected tab in the tab view.
    @State private var selectedTab = 0
    
    /// The orientation of all media in this gallery view. Initially set to `.landscape` until we load the first URL and
    /// determine its orientation, then updated to match the first item's orientation.
    @State private var orientation: MediaOrientation?
    
    /// This essential first image determines the orientation of the gallery view. Whatever orientation this is, so the
    /// rest shall be.
    /// Oh, but also: it's not always an image, so this won't work if it's a video or web link. Oopsie.
    @State private var firstImage: Image?
    
    /// The media service that loads content from URLs and determines the orientation for this gallery.
    @Dependency(\.mediaService) private var mediaService

    var body: some View {
        if let orientation {
            if urls.count == 1, let url = urls.first {
                linkView(url: url, orientation: orientation)
            } else {
                galleryView(orientation: orientation)
            }
        } else {
            loadingView()
        }
    }
    
    /// Produces a tab view with custom paging indicators in the given orientation.
    /// - Parameter orientation: The orientation to use for the gallery.
    /// - Returns: A gallery view in the given orientation.
    private func galleryView(orientation: MediaOrientation) -> some View {
        VStack {
            TabView(selection: $selectedTab) {
                ForEach(urls.indices, id: \.self) { index in
                    AspectRatioContainer(orientation: orientation) {
                        LinkView(url: urls[index])
                            .tag(index)
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(
                minWidth: 0,
                maxWidth: .infinity,
                minHeight: 0,
                maxHeight: .infinity
            )
            .aspectRatio(orientation == .portrait ? 3 / 4 : 4 / 3, contentMode: .fit)
            .padding(.bottom, 10)
            .clipShape(.rect)

            GalleryIndexView(numberOfPages: urls.count, currentIndex: selectedTab)
        }
        .padding(.bottom, 10)
    }
    
    /// Produces a ``LinkView`` with the given URL in the given orientation.
    /// - Parameters:
    ///   - url: The URL to display in the ``LinkView``.
    ///   - orientation: The orientation to use for the ``LinkView``.
    /// - Returns: A ``LinkView`` with the given URL in the given orientation.
    private func linkView(url: URL, orientation: MediaOrientation) -> some View {
        AspectRatioContainer(orientation: orientation) {
            LinkView(url: url)
        }
    }
    
    /// A loading view that fills the space for the given `loadingOrientation` and loads the first URL to determine the
    /// orientation for the gallery.
    /// - Parameter loadingOrientation: The ``MediaOrientation`` to use to display the loading view.
    ///             Defaults to `.landscape`.
    /// - Returns: A loading view in the given `loadingOrientation`.
    private func loadingView(_ loadingOrientation: MediaOrientation = .landscape) -> some View {
        AspectRatioContainer(orientation: loadingOrientation) {
            ProgressView()
        }
        .task {
            guard let url = urls.first else {
                orientation = .landscape
                return
            }

            orientation = await mediaService.orientation(for: url)
        }
    }
}

// Thanks for the [example](https://betterprogramming.pub/custom-paging-ui-in-swiftui-13f1347cf529) Alexandru Turcanu!

/// Custom paging indicators for a `GalleryView`.
fileprivate struct GalleryIndexView: View {
    /// The number of pages in the tab view.
    let numberOfPages: Int

    /// The currently-selected tab in the tab view.
    let currentIndex: Int
    
    /// The size of the circle representing the currently-selected tab.
    private let circleSize: CGFloat = 8.0

    /// The space between circles.
    private let circleSpacing: CGFloat = 6.0
    
    /// The fill style of the circle indicating which tab is selected.
    private let primaryFill = LinearGradient.horizontalAccent

    /// The fill style of the circles indicating tabs that are not selected.
    private let secondaryFill = Color.galleryIndexDotSecondary

    /// The scale of the circles representing tabs that aren't selected, relative to `circleSize`.
    private let smallScale: CGFloat = 0.75

    var body: some View {
        HStack(spacing: circleSpacing) {
            ForEach(0..<numberOfPages, id: \.self) { index in
                Circle()
                    .fill(currentIndex == index ? AnyShapeStyle(primaryFill) : AnyShapeStyle(secondaryFill))
                    .scaleEffect(currentIndex == index ? 1 : smallScale)
                    .frame(width: circleSize, height: circleSize)
                    .transition(AnyTransition.opacity.combined(with: .scale))
                    .id(index)
            }
        }
        .padding(8.0)
        .background(
            Color.galleryIndexViewBackground.cornerRadius(16.0)
        )
    }
}

#Preview("Multiple URLs, landscape image first") {
    let urls = [
        URL(string: "https://image.nostr.build/77713e6c2ef5186d516a6f16fb197fca53a20677c6756a9de1afc2d5e6d96548.jpg")!,
        URL(string: "https://image.nostr.build/486821596f66bcc6bae55544ddf8f00be0e4c2470556d3fee8e2a4ddadd01266.jpg")!,
        URL(string: "https://images.unsplash.com/photo-1715686529501-e097bd9caea7")!,
        URL(string: "https://www.youtube.com/watch?v=sB6HY8r983c")!,
    ]
    return VStack {
        Spacer()
        GalleryView(urls: urls)
        Spacer()
    }
    .background(LinearGradient.cardBackground)
}

#Preview("Multiple URLs, portrait image first") {
    let urls = [
        URL(string: "https://image.nostr.build/486821596f66bcc6bae55544ddf8f00be0e4c2470556d3fee8e2a4ddadd01266.jpg")!,
        URL(string: "https://image.nostr.build/77713e6c2ef5186d516a6f16fb197fca53a20677c6756a9de1afc2d5e6d96548.jpg")!,
    ]
    return VStack {
        Spacer()
        GalleryView(urls: urls)
        Spacer()
    }
    .background(LinearGradient.cardBackground)
}

#Preview("Multiple URLs, mp4 video first") {
    let urls = [
        URL(string: "https://video.nostr.build/2d8a5e74dd940201490a020d5a8f1b0dcca78126a5305f57b001656e8df35605.mp4")!,
        URL(string: "https://images.unsplash.com/photo-1715686529501-e097bd9caea7")!,
    ]
    return VStack {
        Spacer()
        GalleryView(urls: urls)
        Spacer()
    }
    .background(LinearGradient.cardBackground)
}

#Preview("Multiple URLs, YouTube video first") {
    let urls = [
        URL(string: "https://www.youtube.com/watch?v=sB6HY8r983c")!,
        URL(string: "https://images.unsplash.com/photo-1715686529501-e097bd9caea7")!,
    ]
    return VStack {
        Spacer()
        GalleryView(urls: urls)
        Spacer()
    }
    .background(LinearGradient.cardBackground)
}

#Preview("One landscape image") {
    VStack {
        GalleryView(urls: [
            URL(
                string: "https://image.nostr.build/0fa09a19ff2791e9af4c0d7dda6b3fa8a3abc0f152fc55cf17d69b7c59f12d0f.jpg"
            )!
        ])
    }
    .background(LinearGradient.cardBackground)
}

#Preview("One portrait image") {
    VStack {
        GalleryView(urls: [
            URL(
                string: "https://image.nostr.build/b0fe2ee39c5c007b7a9a53190abb6cf9e94d6106555539f8562a29f0a9dbb755.jpg"
            )!
        ])
    }
    .background(LinearGradient.cardBackground)
}
