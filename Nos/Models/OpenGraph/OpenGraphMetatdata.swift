import Foundation

/// Open Graph metadata for a URL.
struct OpenGraphMetadata: Equatable {
    /// The title of the object.
    let title: String?

    /// The type of the object.
    let type: OpenGraphMediaType?

    /// Image metadata, if any.
    let image: OpenGraphMedia?

    /// Video metadata, if any.
    let video: OpenGraphMedia?
}

/// Open Graph metadata for media, such as an image or video.
struct OpenGraphMedia: Equatable {
    /// The URL of the media.
    let url: URL?

    /// The width of the media.
    let width: Double?

    /// The height of the media.
    let height: Double?
    
    /// Initializes an `OpenGraphMedia` with the given parameters. Returns `nil` if all parameter values are `nil`.
    /// - Parameters:
    ///   - url: The URL of the media.
    ///   - width: The width of the media.
    ///   - height: The height of the media.
    init?(url: URL?, width: Double?, height: Double?) {
        if url == nil && width == nil && height == nil {
            return nil
        }
        self.url = url
        self.width = width
        self.height = height
    }
}

/// The type of Open Graph media.
/// - SeeAlso: [The Open Graph protocol: Object Types](https://ogp.me/#types)
enum OpenGraphMediaType {
    /// Video
    case video

    /// Website
    case website

    /// An unknown type
    case unknown
}

/// An Open Graph property in the HTML.
/// - SeeAlso: [The Open Graph protocol](https://ogp.me)
enum OpenGraphProperty: String {
    // MARK: - Title
    case title = "og:title"

    // MARK: - Type
    case type = "og:type"

    // MARK: - Image
    case image = "og:image"
    case imageURL = "og:image:url"
    case imageSecureURL = "og:image:secure_url"
    case imageHeight = "og:image:height"
    case imageWidth = "og:image:width"

    // MARK: - Video
    case video = "og:video"
    case videoURL = "og:video:url"
    case videoSecureURL = "og:video:secure_url"
    case videoHeight = "og:video:height"
    case videoWidth = "og:video:width"
}
