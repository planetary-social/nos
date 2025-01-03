import Foundation
import SwiftSoup

/// Parses the Open Graph metadata from an HTML document using SwiftSoup.
struct SoupOpenGraphParser: OpenGraphParser {
    func metadata(html: Data) -> OpenGraphMetadata? {
        let htmlString = String(decoding: html, as: UTF8.self)
        guard let document = try? SwiftSoup.parse(htmlString) else { return nil }

        let title = stringValue(.title, from: document)
        let type = typeMetadata(from: document)
        let imageMetadata = imageMetadata(from: document)
        let videoMetadata = videoMetadata(from: document)
        return OpenGraphMetadata(title: title, type: type, image: imageMetadata, video: videoMetadata)
    }
}

extension SoupOpenGraphParser {
    /// Gets the Open Graph property value from the given HTML document as a String.
    /// - Parameters:
    ///   - property: The Open Graph property to fetch from the HTML document.
    ///   - document: The HTML document.
    /// - Returns: The value of the Open Graph property as a String, or `nil` if none is found.
    private func stringValue(_ property: OpenGraphProperty, from document: Document) -> String? {
        try? document.select("meta[property=\(property.rawValue)]").attr("content")
    }

    /// Gets the Open Graph property value from the given HTML document as a Double.
    /// - Parameters:
    ///   - property: The Open Graph property to fetch from the HTML document.
    ///   - document: The HTML document.
    /// - Returns: The value of the Open Graph property as a Double, or `nil` if none is found.
    private func doubleValue(_ property: OpenGraphProperty, from document: Document) -> Double? {
        guard let string: String = stringValue(property, from: document) else {
            return nil
        }
        return Double(string)
    }
}

extension SoupOpenGraphParser {
    /// Gets the Open Graph image metadata from the given HTML document.
    /// - Parameter document: The HTML document.
    /// - Returns: The Open Graph image metadata, or `nil` if none is found.
    private func imageMetadata(from document: Document) -> OpenGraphMedia? {
        let url = imageURL(from: document)
        let width = doubleValue(.imageWidth, from: document)
        let height = doubleValue(.imageHeight, from: document)

        return OpenGraphMedia(url: url, width: width, height: height)
    }
    
    /// Gets the Open Graph type metadata from the given HTML document.
    /// - Parameter document: The HTML document.
    /// - Returns: The Open Graph type metadata, or `nil` if none is found
    private func typeMetadata(from document: Document) -> OpenGraphMediaType? {
        guard let type: String = stringValue(.type, from: document) else {
            return nil
        }

        if type.starts(with: "video") {
            return .video
        } else if type == "website" {
            return .website
        } else {
            return .unknown
        }
    }

    /// Gets the Open Graph video metadata from the given HTML document.
    /// - Parameter document: The HTML document.
    /// - Returns: The Open Graph video metadata, or `nil` if none is found.
    private func videoMetadata(from document: Document) -> OpenGraphMedia? {
        let url = videoURL(from: document)
        let width = doubleValue(.videoWidth, from: document)
        let height = doubleValue(.videoHeight, from: document)

        return OpenGraphMedia(url: url, width: width, height: height)
    }
}

extension SoupOpenGraphParser {
    /// Gets the Open Graph image URL from the given HTML document.
    /// - Parameter document: The HTML document.
    /// - Returns: The Open Graph image URL, or `nil` if none is found.
    /// - Note: The image URL may be in a variety of properties, including `"og:image"`, `"og:image:url`, or
    ///        `"og:image:secure_url"`.
    private func imageURL(from document: Document) -> URL? {
        if let url = stringValue(.image, from: document), !url.isEmpty {
            return URL(string: url)
        } else if let url = stringValue(.imageURL, from: document), !url.isEmpty {
            return URL(string: url)
        } else if let url = stringValue(.imageSecureURL, from: document), !url.isEmpty {
            return URL(string: url)
        } else {
            return nil
        }
    }

    /// Gets the Open Graph video URL from the given HTML document.
    /// - Parameter document: The HTML document.
    /// - Returns: The Open Graph video URL, or `nil` if none is found.
    /// - Note: The video URL may be in a variety of properties, including `"og:video"`, `"og:video:url`, or
    ///        `"og:video:secure_url"`.
    private func videoURL(from document: Document) -> URL? {
        if let url = stringValue(.video, from: document), !url.isEmpty {
            return URL(string: url)
        } else if let url = stringValue(.videoURL, from: document), !url.isEmpty {
            return URL(string: url)
        } else if let url = stringValue(.videoSecureURL, from: document), !url.isEmpty {
            return URL(string: url)
        } else {
            return nil
        }
    }
}
