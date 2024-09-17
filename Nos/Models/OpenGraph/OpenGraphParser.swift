import Foundation

/// Parses the Open Graph metadata from an HTML document.
protocol OpenGraphParser {
    /// Fetches the Open Graph video metadata from the given HTML document.
    /// - Parameter html: An HTML document.
    /// - Returns: The Open Graph video metadata from the HTML.
    func videoMetadata(html: Data) -> OpenGraphMedia?
}

/// An Open Graph property in the HTML.
enum OpenGraphProperty: String {
    case videoHeight = "og:video:height"
    case videoWidth = "og:video:width"
}
