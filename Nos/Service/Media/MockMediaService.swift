import Foundation

/// A mock media service for testing.
struct MockMediaService: MediaService {
    func orientation(for url: URL) async -> MediaOrientation {
        .landscape
    }
}
