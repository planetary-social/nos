import LinkPresentation
import SDWebImageSwiftUI
import SwiftUI

struct ImageLinkButton: View {
    let url: URL

    @State private var isViewerPresented = false

    var body: some View {
        Button {
            isViewerPresented = true
        } label: {
            let image = WebImage(url: url)
                .resizable()
                .indicator(.activity)

            ZStack {
                image
                    .blur(radius: 10)
                    .clipped()

                image
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .cornerRadius(8)
        }
        .sheet(isPresented: $isViewerPresented) {
            ImageViewer(url: url)
        }
    }
}

struct HeroImageButton: View {
    let url: URL

    @State private var isViewerPresented = false

    var body: some View {
        Button {
            isViewerPresented = true
        } label: {
            WebImage(url: url)
                .resizable()
                .indicator(.activity)
                .aspectRatio(contentMode: .fill)
                .clipped()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .sheet(isPresented: $isViewerPresented) {
            ImageViewer(url: url)
        }
    }
}

struct LinkPreview: View {

    let url: URL

    var body: some View {
        if url.isImage {
            ImageLinkButton(url: url)
        } else {
            LPLinkViewRepresentable(url: url)
        }
    }
}

/// A view that displays an Open Graph Protocol preview of the given URL.
struct LPLinkViewRepresentable: UIViewRepresentable {

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

struct LinkPreviewCarousel: View {

    var links: [URL]

    var body: some View {
        if links.count == 1, let url = links.first {

            if url.isImage {
                HeroImageButton(url: url)
            } else {
                LinkPreview(url: url)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 0)
                    .padding(.bottom, 15)
            }
        } else {
            TabView {
                ForEach(links, id: \.self.absoluteURL) { url in
                    LinkPreview(url: url)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 0)
                }
            }
            .tabViewStyle(.page)
            .frame(height: 320)
            .padding(.bottom, 15)
        }
    }
}

struct LinkPreview_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // swiftlint:disable line_length
            LinkPreviewCarousel(links: [
                URL(
                    string:
                        "https://image.nostr.build/77713e6c2ef5186d516a6f16fb197fca53a20677c6756a9de1afc2d5e6d96548.jpg"
                )!,
                URL(
                    string:
                        "https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Ftse1.mm.bing.net%2Fth%3Fid%3DOIP.r1ZOH5E3M6WiK6aw5GRdlAHaEK%26pid%3DApi&f=1&ipt=42ae9de7730da3bda152c5980cd64b14ccef37d8f55b8791e41b4667fc38ddf1&ipo=images"
                )!,
                URL(string: "https://youtu.be/5qvdbyRH9wA?si=y_KTgLR22nH0-cs8")!,
                URL(
                    string:
                        "https://image.nostr.build/d5e38e7d864a344872d922d7f78daf67b0d304932fcb7fe22d35263c2fcf11c2.jpg"
                )!,
            ])

            LinkPreviewCarousel(links: [
                URL(
                    string:
                        "https://image.nostr.build/d5e38e7d864a344872d922d7f78daf67b0d304932fcb7fe22d35263c2fcf11c2.jpg"
                )!
            ])
            // swiftlint:enable line_length
        }
    }
}
