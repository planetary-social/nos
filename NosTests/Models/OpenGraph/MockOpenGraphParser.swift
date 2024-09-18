import Foundation

/// A mock Open Graph parser that can be used for testing.
struct MockOpenGraphParser: OpenGraphParser {
    func videoMetadata(html: Data) -> OpenGraphMedia? {
        nil
    }
}
