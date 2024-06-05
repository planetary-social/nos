import Foundation

/// Defines the requests that can be sent to the file storage API.
/// - Note: Implements [NIP-96](https://github.com/nostr-protocol/nips/blob/master/96.md)
enum FileStorageAPIRequest {
    /// A request for server info about the API. The main info we use from this is the API URL.
    case serverInfo
}

extension FileStorageAPIRequest {
    private var baseURLString: String {
        "https://nostr.build"
    }

    private var path: String {
        "/.well-known/nostr/nip96.json"
    }

    var urlRequest: URLRequest? {
        guard var components = URLComponents(string: baseURLString) else {
            return nil
        }
        components.path = path

        guard let url = components.url else {
            return nil
        }
        return URLRequest(url: url)
    }
}
