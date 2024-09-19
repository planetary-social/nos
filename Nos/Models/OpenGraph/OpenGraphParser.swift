import Foundation

/// Parses the Open Graph metadata from an HTML document.
protocol OpenGraphParser {
    /// Fetches the Open Graph metadata from the given HTML document.
    /// - Parameter html: An HTML document.
    /// - Returns: The Open Graph metadata from the HTML.
    func metadata(html: Data) -> OpenGraphMetadata?
}
