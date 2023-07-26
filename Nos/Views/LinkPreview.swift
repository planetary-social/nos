//
//  LinkPreview.swift
//  Nos
//
//  Created by Matthew Lorentz on 7/14/23.
//

import SwiftUI
import LinkPresentation

/// A view that displays an Open Graph Protocol preview of the given URL.
struct LinkPreview: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> LPLinkView {
        let linkView = LPLinkView(url: url)
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

struct LinkPreview_Previews: PreviewProvider {
    static var previews: some View {
        // swiftlint:disable line_length
        LinkPreview(
            url: URL(string: "https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Ftse1.mm.bing.net%2Fth%3Fid%3DOIP.r1ZOH5E3M6WiK6aw5GRdlAHaEK%26pid%3DApi&f=1&ipt=42ae9de7730da3bda152c5980cd64b14ccef37d8f55b8791e41b4667fc38ddf1&ipo=images")!
        )
        .padding(.horizontal, 15)
        // swiftlint:enable line_length
    }
}
