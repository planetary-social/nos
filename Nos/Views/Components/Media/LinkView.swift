import SwiftUI

/// Displays a preview of content from a URL or an image, depending on the URL.
struct LinkView: View {
    /// The URL of the content to display.
    let url: URL

    var body: some View {
        if url.isImage {
            ImageButton(url: url)
        } else {
            LPLinkViewRepresentable(url: url)
        }
    }
}

#Preview("Video") {
    LinkView(url: URL(string: "https://www.youtube.com/watch?v=sB6HY8r983c")!)
}

#Preview("Image") {
    LinkView(
        url: URL(
            string: "https://image.nostr.build/d5e38e7d864a344872d922d7f78daf67b0d304932fcb7fe22d35263c2fcf11c2.jpg"
        )!
    )
}
