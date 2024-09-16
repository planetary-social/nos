import Foundation
import SwiftSoup

struct SoupOpenGraphParser: OpenGraphParser {
    func videoMetadata(html: Data) -> OpenGraphMedia? {
        let htmlString = String(decoding: html, as: UTF8.self)
        guard let document = try? SwiftSoup.parse(htmlString) else { return nil }

        guard let widthString = openGraphProperty(.videoWidth, from: document),
            let width = Double(widthString) else {
            return nil
        }
        guard let heightString = openGraphProperty(.videoHeight, from: document),
            let height = Double(heightString) else {
            return nil
        }

        return OpenGraphMedia(url: nil, type: .video, width: width, height: height)
    }
}

extension SoupOpenGraphParser {
    private func openGraphProperty(_ property: OpenGraphProperty, from document: Document) -> String? {
        try? document.select("meta[property=\(property.rawValue)]").attr("content")
    }
}

enum OpenGraphProperty: String {
    case videoWidth = "og:video:width"
    case videoHeight = "og:video:height"
}
