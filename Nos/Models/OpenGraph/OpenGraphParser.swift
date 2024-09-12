import Foundation

protocol OpenGraphParser {
    func videoMetadata(html: String) -> OpenGraphMedia?
}
