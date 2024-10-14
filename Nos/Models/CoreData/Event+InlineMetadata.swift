import Foundation

extension Event {
    /// Returns an ``InlineMetadataCollection`` for the event, if any exists. Inline metadata comes from the
    /// `imeta` tag as described in [NIP-92](https://github.com/nostr-protocol/nips/blob/master/92.md)
    var inlineMetadata: InlineMetadataCollection? {
        guard let tags = allTags as? [[String]] else {
            return nil
        }

        let metadataTags = tags.filter({ $0.first == "imeta" })
            .compactMap { InlineMetadataTag(imetaTag: $0) }
        return InlineMetadataCollection(tags: metadataTags)
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

    /// Initializes an ``InlineMetadataTag`` with the given URL and dimensions.
    /// - Parameters:
    ///   - url: The URL of the media described by this metadata.
    ///   - dimensions: The dimensions of the media described by this metadata.
    init(url: String, dimensions: CGSize?) {
        self.url = url
        self.dimensions = dimensions
    }

    /// Initializes an ``InlineMetadataTag`` with the given `imeta` tag from the JSON.
    /// - Parameter imetaTag: The `imeta` tag from the JSON.
    init?(imetaTag: [String]) {
        guard let urlPair = imetaTag.first(where: { $0.starts(with: "url") }),
            let url = urlPair.components(separatedBy: " ").last
        else {
            return nil
        }
        self.url = url

        let dimPair = imetaTag.first(where: { $0.starts(with: "dim") })
        let widthXHeight = dimPair?.components(separatedBy: " ").last

        if let components = widthXHeight?.components(separatedBy: "x"),
            let width = components.first,
            let height = components.last,
            let widthValue = Double(width),
            let heightValue = Double(height)
        {
            self.dimensions = CGSize(width: widthValue, height: heightValue)
        } else {
            self.dimensions = nil
        }
    }
}

/// A collection of ``InlineMetadataTag`` objects accessible by URL, similar to a dictionary.
struct InlineMetadataCollection {
    private var metadata: [String: InlineMetadataTag]

    init(tags: [InlineMetadataTag] = []) {
        metadata = .init()
        for tag in tags {
            guard metadata[tag.url] == nil else { continue }
            metadata[tag.url] = tag
        }
    }

    mutating func insert(_ inlineMetadataTag: InlineMetadataTag) {
        metadata[inlineMetadataTag.url] = inlineMetadataTag
    }

    subscript(url: String?) -> InlineMetadataTag? {
        guard let url else { return nil }
        return metadata[url]
    }
}
