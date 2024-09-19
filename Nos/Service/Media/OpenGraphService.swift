import Dependencies
import Foundation

/// A service that fetches metadata for a URL.
protocol OpenGraphService {
    /// Fetches metadata for the given URL.
    /// - Parameter url: The URL to fetch.
    /// - Returns: The Open Graph metadata for the URL.
    func fetchMetadata(for url: URL) async throws -> OpenGraphMetadata?
}

/// A default implementation for `OpenGraphService`.
struct DefaultOpenGraphService: OpenGraphService {
    let parser: OpenGraphParser

    @Dependency(\.urlSession) var session

    init(parser: OpenGraphParser = SoupOpenGraphParser()) {
        self.parser = parser
    }

    func fetchMetadata(for url: URL) async throws -> OpenGraphMetadata? {
        var request = URLRequest(url: url) // example.com/video.mp4 // example.com/video
        // some websites, like YouTube, only provide metadata for specific User-Agent values
        request.setValue("facebookexternalhit/1.1 Facebot Twitterbot/1.0", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await session.data(for: request)
        if let httpURLResponse = (response as? HTTPURLResponse) {
            for headerField in httpURLResponse.allHeaderFields {
                print("headerField: \(headerField)")
                if let key = headerField.key as? String,
                    let value = headerField.value as? String,
                    key == "Content-Type",
                    value.contains("text/html") {
                    // parse
                    return parser.metadata(html: data)
                }
            }
        }
        return nil
    }
}
