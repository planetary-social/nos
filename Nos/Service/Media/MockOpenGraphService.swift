import Foundation

struct MockOpenGraphService: OpenGraphService {
    func fetchMetadata(for url: URL) async throws -> OpenGraphMetadata? {
        nil
    }
}
