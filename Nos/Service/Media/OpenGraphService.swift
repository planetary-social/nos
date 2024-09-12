import Foundation

protocol OpenGraphService {
    func fetchMetadata(for url: URL) async throws -> OpenGraphMetadata
}

struct DefaultOpenGraphService: OpenGraphService {
    let session: URLSessionProtocol

    func fetchMetadata(for url: URL) async throws -> OpenGraphMetadata {
        let request = URLRequest(url: url)
        let data = try await session.data(for: request)
        return OpenGraphMetadata(media: nil)
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
