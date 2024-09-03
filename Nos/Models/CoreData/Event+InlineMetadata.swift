import Foundation

extension Event {
    /// Inline metadata describing media in an ``Event``.
    struct InlineMetadata {
        /// The URL of the media.
        let url: String

        /// The dimensions of the media in pixels.
        let dimensions: CGSize?
    }
    
    /// Returns ``InlineMetadata`` for the event, if any exists. Inline metadata comes from the `imeta` tag as described
    /// in [NIP-92](https://github.com/nostr-protocol/nips/blob/master/92.md)
    var inlineMetadata: [InlineMetadata] {
        guard let tags = allTags as? [[String]] else {
            return []
        }

        let imetaTags = tags.filter({ $0.first == "imeta" })

        var result = [InlineMetadata]()
        for imetaTag in imetaTags {
            guard let urlPair = imetaTag.first(where: { $0.starts(with: "url") }),
                let url = urlPair.components(separatedBy: " ").last else {
                continue
            }

            let dimPair = imetaTag.first(where: { $0.starts(with: "dim") })
            let widthXHeight = dimPair?.components(separatedBy: " ").last

            let dimensions: CGSize?
            if let components = widthXHeight?.components(separatedBy: "x"),
                let width = components.first,
                let height = components.last,
                let widthValue = Double(width),
                let heightValue = Double(height) {
                dimensions = CGSize(width: widthValue, height: heightValue)
            } else {
                dimensions = nil
            }

            result.append(InlineMetadata(url: url, dimensions: dimensions))
        }

        return result
    }
}
