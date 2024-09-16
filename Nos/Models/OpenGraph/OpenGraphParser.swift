import Foundation

/// Parses the Open Graph metadata from an HTML document.
protocol OpenGraphParser {
    func videoMetadata(html: Data) -> OpenGraphMedia?
}

struct UnimplementedOpenGraphParser: OpenGraphParser {
    func videoMetadata(html: Data) -> OpenGraphMedia? {
        nil
    }
}
