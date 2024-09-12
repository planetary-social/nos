import Foundation

protocol OpenGraphParser {
    func videoMetadata(html: Data) -> OpenGraphMedia?
}

struct UnimplementedOpenGraphParser: OpenGraphParser {
    func videoMetadata(html: Data) -> OpenGraphMedia? {
        nil
    }
}
