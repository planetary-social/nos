import Dependencies
import SwiftUI

/// Displays an array of URLs in a tab view with custom paging indicators.
/// If only one URL is provided, displays a ``LinkView`` with the URL.
struct GalleryView: View {
    /// The URLs of the content to display.
    let urls: [URL]

    /// Inline metadata describing the data in ``urls``.
    let metadata: InlineMetadataCollection?

    /// The currently-selected tab in the tab view.
    @State private var selectedTab = 0
    
    /// The orientation for this gallery view.
    @State private var orientation: MediaOrientation?
    
    /// The media service that loads content from URLs and determines the orientation for this gallery.
    @Dependency(\.mediaService) private var mediaService
    
    /// The orientation determined by the `metadata`, if any.
    private var metadataOrientation: MediaOrientation? {
        metadata?[urls.first?.absoluteString]?.orientation
    }

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
        VStack(spacing: 0) {
            Divider()
                .overlay(Color.cardDividerTop)

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
            .aspectRatio(orientation.aspectRatio, contentMode: .fit)
            .clipShape(.rect)

            Divider()
                .overlay(Color.cardDividerTop)
                .shadow(color: .cardDividerTopShadow, radius: 0, x: 0, y: 1)
                .padding(.bottom, 10)

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
    
    /// A loading view that determines the orientation for the gallery. When possible, the aspect ratio of the
    /// loading view matches the aspect ratio of the gallery. Otherwise, `landscape`.
    /// - Returns: A loading view in the aspect ratio that matches the gallery media when possible.
    private func loadingView() -> some View {
        AspectRatioContainer(orientation: metadataOrientation ?? .landscape) {
            ProgressView()
        }
        .task {
            guard let firstURL = urls.first else {
                orientation = .landscape
                return
            }

            // if we can determine the orientation from the metadata we have, great!
            // if not, download the data from the first URL to determine the orientation
            if let metadataOrientation {
                orientation = metadataOrientation
            } else {
                orientation = await mediaService.orientation(for: firstURL)
            }
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
    private let smallScale: CGFloat = 0.5

    /// The maximum distance (in pages) from the selected index for visible circles.
    /// Circles outside this range are not displayed.
    private let maxDistance = 6

    var body: some View {
        HStack(spacing: circleSpacing) {
            ForEach(0..<numberOfPages, id: \.self) { index in
                if shouldShowIndex(index) {
                    Circle()
                        .fill(currentIndex == index ? AnyShapeStyle(primaryFill) : AnyShapeStyle(secondaryFill))
                        .scaleEffect(scaleFor(index))
                        .frame(width: circleSize, height: circleSize)
                        .transition(AnyTransition.opacity.combined(with: .scale))
                        .id(index)
                }
            }
        }
        .padding(8.0)
        .background(
            Color.galleryIndexViewBackground.cornerRadius(16.0)
        )
    }

    /// Determines whether a given index should be displayed in the view.
    ///
    /// - Parameter index: The index of the page to evaluate.
    /// - Returns: `true` if the index is within `maxDistance` of the `currentIndex`; otherwise, `false`.
    private func shouldShowIndex(_ index: Int) -> Bool {
        ((currentIndex - maxDistance)...(currentIndex + maxDistance)).contains(index)
    }

    /// Calculates the scale factor for a circle at a given index.
    ///
    /// - Parameter index: The index of the page to evaluate.
    /// - Returns: A scale factor based on the distance from `currentIndex`.
    private func scaleFor(_ index: Int) -> CGFloat {
        // Show all circles at full size if there are 6 or fewer pages
        if numberOfPages <= 6 {
            return 1.0
        }

        // Calculate the distance from the selected page
        let distanceFromCenter = abs(index - currentIndex)

        // Scale circles based on distance, shrinking to `smallScale` at max distance
        let scaleRange = 1.0 - smallScale
        let scaleFactor = 1.0 - (CGFloat(distanceFromCenter) / CGFloat(maxDistance)) * scaleRange

        // Prevent scale from dropping below `smallScale`
        return max(smallScale, scaleFactor)
    }
}

#Preview("Multiple URLs, landscape image first") {
    let urls = [
        URL(string: "https://image.nostr.build/77713e6c2ef5186d516a6f16fb197fca53a20677c6756a9de1afc2d5e6d96548.jpg")!,
        URL(string: "https://example.com/no.jpg")!,
        URL(string: "https://image.nostr.build/486821596f66bcc6bae55544ddf8f00be0e4c2470556d3fee8e2a4ddadd01266.jpg")!,
        URL(string: "https://images.unsplash.com/photo-1715686529501-e097bd9caea7")!,
        URL(string: "https://www.youtube.com/watch?v=sB6HY8r983c")!,
    ]
    return VStack {
        Spacer()
        GalleryView(urls: urls, metadata: nil)
        Spacer()
    }
    .background(LinearGradient.cardBackground)
}

#Preview("Multiple URLs, portrait image first") {
    let urls = [
        URL(string: "https://image.nostr.build/486821596f66bcc6bae55544ddf8f00be0e4c2470556d3fee8e2a4ddadd01266.jpg")!,
        URL(string: "https://example.com/no.jpg")!,
        URL(string: "https://image.nostr.build/77713e6c2ef5186d516a6f16fb197fca53a20677c6756a9de1afc2d5e6d96548.jpg")!,
    ]
    return VStack {
        Spacer()
        GalleryView(urls: urls, metadata: nil)
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
        GalleryView(urls: urls, metadata: nil)
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
        GalleryView(urls: urls, metadata: nil)
        Spacer()
    }
    .background(LinearGradient.cardBackground)
}

#Preview("Landscape image with metadata") {
    let url = "https://image.nostr.build/0fa09a19ff2791e9af4c0d7dda6b3fa8a3abc0f152fc55cf17d69b7c59f12d0f.jpg"
    let urls = [URL(string: url)!]
    let metadataTag = InlineMetadataTag(url: url, dimensions: CGSize(width: 1252, height: 835))
    let collection = InlineMetadataCollection(tags: [metadataTag])
    return VStack {
        GalleryView(urls: urls, metadata: collection)
    }
    .background(LinearGradient.cardBackground)
}

#Preview("Portrait image with metadata") {
    let url = "https://image.nostr.build/b0fe2ee39c5c007b7a9a53190abb6cf9e94d6106555539f8562a29f0a9dbb755.jpg"
    let urls = [
        URL(string: url)!
    ]
    let metadataTag = InlineMetadataTag(url: url, dimensions: CGSize(width: 1, height: 2))
    let collection = InlineMetadataCollection(tags: [metadataTag])
    return VStack {
        GalleryView(urls: urls, metadata: collection)
    }
    .background(LinearGradient.cardBackground)
}

#Preview("Portrait image") {
    let url = "https://image.nostr.build/486821596f66bcc6bae55544ddf8f00be0e4c2470556d3fee8e2a4ddadd01266.jpg"
    let urls = [
        URL(string: url)!
    ]
    return VStack {
        GalleryView(urls: urls, metadata: nil)
    }
    .background(LinearGradient.cardBackground)
}
