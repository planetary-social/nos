import Foundation

/// A service that fetches metadata for a URL.
protocol OpenGraphService {
    /// Fetches metadata for the given URL.
    /// - Parameter url: The URL to fetch.
    /// - Returns: The Open Graph metadata for the URL.
    func fetchMetadata(for url: URL) async throws -> OpenGraphMetadata
}

/// A default implementation for `OpenGraphService`.
struct DefaultOpenGraphService: OpenGraphService {
    let session: URLSessionProtocol
    let parser: OpenGraphParser

    func fetchMetadata(for url: URL) async throws -> OpenGraphMetadata {
        let request = URLRequest(url: url)
        let (data, _) = try await session.data(for: request)
        let videoMetadata = parser.videoMetadata(html: data)
        return OpenGraphMetadata(media: videoMetadata)
    }
}

/// Open Graph metadata for a URL.
struct OpenGraphMetadata: Equatable {
    let media: OpenGraphMedia?
}

/// Open Graph metadata for media, such as an image or video.
struct OpenGraphMedia: Equatable {
    let type: OpenGraphMediaType?
    let width: Double?
    let height: Double?
}

/// The type of Open Graph media.
enum OpenGraphMediaType {
    case image
    case video
}
