import Foundation
import SwiftSoup

/// Parses the Open Graph metadata from an HTML document using SwiftSoup.
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

        return OpenGraphMedia(type: .video, width: width, height: height)
    }
}

extension SoupOpenGraphParser {
    /// Gets the Open Graph property value from the given HTML document.
    /// - Parameters:
    ///   - property: The Open Graph property to fetch from the HTML document.
    ///   - document: The HTML document.
    /// - Returns: The value of the Open Graph property, or `nil` if none is found.
    private func openGraphProperty(_ property: OpenGraphProperty, from document: Document) -> String? {
        try? document.select("meta[property=\(property.rawValue)]").attr("content")
    }
}
