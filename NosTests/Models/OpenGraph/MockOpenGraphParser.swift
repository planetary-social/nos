import Foundation

/// A mock Open Graph parser that can be used for testing.
final class MockOpenGraphParser: OpenGraphParser {
    var metadataCallCount = 0
    
    func metadata(html: Data) -> OpenGraphMetadata? {
        metadataCallCount += 1
        return nil
    }
}
