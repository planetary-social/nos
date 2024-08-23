import SDWebImageSwiftUI
import SwiftUI

/// Displays an array of URLs in a tab view with custom paging indicators.
/// If only one URL is provided, displays an `ImageButton` or `LinkPreview` depending on the URL.
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

    var body: some View {
        if let orientation {
            if urls.count == 1, let url = urls.first {
                AspectRatioContainer(orientation: orientation) {
                    LinkView(url: url)
                }
            } else {
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
        } else {
            AspectRatioContainer(orientation: .landscape) {
                ActivityIndicator(.constant(true))
            }
            .task {
                if let url = urls.first, url.isImage {
                    SDWebImageDownloader().downloadImage(with: urls.first) { image, _, _, _ in
                        if let image, image.size.height > image.size.width {
                            orientation = .portrait
                        } else {
                            orientation = .landscape
                        }
                    }
                } else { // it must be a video or a web link of some sort... TODO: figure out its orientation
                    orientation = .landscape
                }
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

#Preview("Multiple URLs") {
    let urls = [
        URL(string: "https://image.nostr.build/77713e6c2ef5186d516a6f16fb197fca53a20677c6756a9de1afc2d5e6d96548.jpg")!,
        URL(string: "https://youtu.be/5qvdbyRH9wA?si=y_KTgLR22nH0-cs8")!,
        URL(string: "https://image.nostr.build/d5e38e7d864a344872d922d7f78daf67b0d304932fcb7fe22d35263c2fcf11c2.jpg")!,
        URL(string: "https://images.unsplash.com/photo-1715686529501-e097bd9caea7")!,
    ]
    return VStack {
        Spacer()
        GalleryView(urls: urls)
        Spacer()
    }
    .background(LinearGradient.cardBackground)
}

#Preview("One image URL") {
    VStack {
        GalleryView(urls: [
            URL(
                string: "https://image.nostr.build/d5e38e7d864a344872d922d7f78daf67b0d304932fcb7fe22d35263c2fcf11c2.jpg"
            )!
        ])
    }
    .background(LinearGradient.cardBackground)
}
