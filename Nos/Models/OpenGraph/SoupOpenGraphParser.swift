import Foundation
import SwiftSoup

struct SoupOpenGraphParser: OpenGraphParser {
    func videoMetadata(html: Data) -> OpenGraphMedia? {
        let htmlString = String(decoding: html, as: UTF8.self)
        guard let document = try? SwiftSoup.parse(htmlString) else { return nil }
        guard let metaTags = try? document.select("meta") else { return nil }

        var videoWidth: Double?
        var videoHeight: Double?

        for metaTag in metaTags {
            if let property = try? metaTag.attr("property") {
                if property == "og:video:width", let width: String = try? metaTag.attr("content") {
                    videoWidth = Double(width)
                } else if property == "og:video:height", let height: String = try? metaTag.attr("content") {
                    videoHeight = Double(height)
                }
            }
        }

        return OpenGraphMedia(url: nil, type: .video, width: videoWidth, height: videoHeight)
    }
}
