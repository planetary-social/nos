import Foundation

protocol OpenGraphService {
    func fetchMetadata(for url: URL) async throws -> OpenGraphMetadata
}

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

struct OpenGraphMetadata: Equatable {
    let media: OpenGraphMedia?
}

struct OpenGraphMedia: Equatable {
    let url: String?
    let type: OpenGraphMediaType?
    let width: Double?
    let height: Double?
}

enum OpenGraphMediaType {
    case image
    case video
}
