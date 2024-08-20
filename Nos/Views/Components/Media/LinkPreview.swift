import SwiftUI
import LinkPresentation
import SDWebImageSwiftUI

/// Shows an image button or a link view, depending on the URL.
struct LinkPreview: View {
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

/// A view that displays an Open Graph Protocol preview of the given URL.
struct LPLinkViewRepresentable: UIViewRepresentable {
    /// The URL of the content to display.
    let url: URL

    func makeUIView(context: Context) -> LPLinkView {
        let linkView = LPLinkView(url: url)
        linkView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        linkView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        linkView.sizeToFit()
        return linkView
    }
    
    func updateUIView(_ uiView: LPLinkView, context: Context) {
        let provider = LPMetadataProvider()
        provider.startFetchingMetadata(for: url) { metadata, error in
            guard let metadata = metadata, error == nil else { return }
            DispatchQueue.main.async {
                uiView.metadata = metadata
            }
        }
    }
}
