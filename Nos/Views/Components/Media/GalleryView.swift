import SwiftUI

/// Displays an array of URLs in a tab view with custom paging indicators.
/// If only one URL is provided, displays an `ImageButton` or `LinkPreview` depending on the URL.
struct GalleryView: View {
    /// The URLs of the content to display.
    var urls: [URL]
    
    /// The currently-selected tab in the tab view.
    @State private var selectedTab = 0

    var body: some View {
        if urls.count == 1, let url = urls.first {
            if url.isImage {
                ImageButton(url: url)
            } else {
                LinkView(url: url)
//                    .padding(.horizontal, 15)
//                    .padding(.vertical, 0)
//                    .padding(.bottom, 15)
            }
        } else {
            VStack {
                TabView(selection: $selectedTab) {
                    ForEach(urls.indices, id: \.self) { index in
                        LinkView(url: urls[index])
                            .frame(maxWidth: .infinity)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 320)
                .padding(.bottom, 10)

                GalleryIndexView(numberOfPages: urls.count, currentIndex: selectedTab)
            }
            .padding(.bottom, 10)
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

    private let circleSize: CGFloat = 10.0
    private let circleSpacing: CGFloat = 8.0

    private let primaryColor = Color.orange
    private let secondaryColor = Color.gray.opacity(0.6)

    private let smallScale: CGFloat = 0.8

    private let padding = 8.0
    private let cornerRadius = 16.0

    var body: some View {
        HStack(spacing: circleSpacing) {
            ForEach(0..<numberOfPages, id: \.self) { index in // 1
                Circle()
                    .fill(currentIndex == index ? primaryColor : secondaryColor) // 2
                    .scaleEffect(currentIndex == index ? 1 : smallScale)

                    .frame(width: circleSize, height: circleSize)

                    .transition(AnyTransition.opacity.combined(with: .scale)) // 3

                    .id(index) // 4
            }
        }
        .padding(padding)
        .background(
            Color.black.cornerRadius(cornerRadius)
        )
    }
}

#Preview("Multiple URLs") {
    GalleryView(urls: [
        URL(string: "https://image.nostr.build/77713e6c2ef5186d516a6f16fb197fca53a20677c6756a9de1afc2d5e6d96548.jpg")!,
        URL(string: "https://youtu.be/5qvdbyRH9wA?si=y_KTgLR22nH0-cs8")!,
        URL(string: "https://image.nostr.build/d5e38e7d864a344872d922d7f78daf67b0d304932fcb7fe22d35263c2fcf11c2.jpg")!,
        URL(string: "https://images.unsplash.com/photo-1715686529501-e097bd9caea7")!,
    ])
}

#Preview("One image URL") {
    GalleryView(urls: [
        URL(string: "https://image.nostr.build/d5e38e7d864a344872d922d7f78daf67b0d304932fcb7fe22d35263c2fcf11c2.jpg")!
    ])
}
