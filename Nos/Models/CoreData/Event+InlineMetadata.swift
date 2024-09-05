import Foundation

extension Event {
    /// Returns an ``InlineMetadataCollection`` for the event, if any exists. Inline metadata comes from the
    /// `imeta` tag as described in [NIP-92](https://github.com/nostr-protocol/nips/blob/master/92.md)
    var inlineMetadata: InlineMetadataCollection? {
        guard let tags = allTags as? [[String]] else {
            return nil
        }

        let imetaTags = tags.filter({ $0.first == "imeta" })

        var collection = InlineMetadataCollection()
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

            collection.insert(InlineMetadataTag(url: url, dimensions: dimensions))
        }
        return collection
    }
}

/// Inline metadata describing media in an ``Event``.
struct InlineMetadataTag {
    /// The URL of the media.
    let url: String

    /// The dimensions of the media in pixels.
    let dimensions: CGSize?

    /// The orientation of the media, as determined by the `dimensions`. If `dimensions` is `nil`, returns `nil`.
    /// If the height is greater than the width, returns `.portrait`. Otherwise, returns `.landscape`.
    var orientation: MediaOrientation? {
        guard let dimensions else { return nil }
        if dimensions.height > dimensions.width {
            return .portrait
        } else {
            return .landscape
        }
    }
}

/// A collection of ``InlineMetadataTag`` objects accessible by URL, similar to a dictionary.
struct InlineMetadataCollection {
    private var metadata: [String: InlineMetadataTag]

    init(tags: [InlineMetadataTag] = []) {
        metadata = Dictionary(uniqueKeysWithValues: tags.map { ($0.url, $0) })
    }

    mutating func insert(_ inlineMetadataTag: InlineMetadataTag) {
        metadata[inlineMetadataTag.url] = inlineMetadataTag
    }

    subscript(url: String?) -> InlineMetadataTag? {
        guard let url else { return nil }
        return metadata[url]
    }
}
