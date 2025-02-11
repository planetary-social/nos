import Foundation

/// The NamesAPI service is in charge of creating and deleting nos.social
/// usernames and verifying if a NIP-05 or nos.social username can be associated
/// or not.
final class NamesAPI {

    /// A shared URLCache instance to store responses from NIP-05 providers
    private let urlCache = URLCache(
        memoryCapacity: 4 * 1024 * 1024, // 4 MB
        diskCapacity: 20 * 1024 * 1024,  // 20 MB
        directory: .cachesDirectory.appending(component: "NamesAPI")
    )

    /// The maximum Data size we allow when caching responses to prevent
    /// a large response from taking all the space.
    private lazy var maximumURLCacheItemSize: Int = {
        // Use the 5% of disk cache size
        let maximum = Double(urlCache.diskCapacity) * 0.05
        return Int(
            exactly: maximum.rounded(.toNearestOrEven)
        ) ?? 1024
    }()

    /// A shared URLSession instance to fetch responses from NIP-05 providers
    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = urlCache
        return URLSession(
            configuration: configuration
        )
    }()

    private enum Error: LocalizedError {
        case unexpected
        case usernameNotAvailable

        var errorDescription: String? {
            switch self {
            case .unexpected:
                return "Unexpected"
            case .usernameNotAvailable:
                return String(localized: "usernameAlreadyClaimed")
            }
        }
    }

    private enum HTTPMethod: String {
        case delete = "DELETE"
        case post = "POST"
    }

    /// Structure that encapsulates the result of requesting the
    /// `/.well-known/nostr.json` path to a given server.
    private enum PingResult {
        /// The npub registered in the server matches with the provided public
        /// key.
        case match
        /// The npub registered in the server doesn't match with the provided
        /// public key.
        case mismatch
        /// The server returned a 404 Not Found response.
        case notFound
        /// The server returned an unexpected response.
        case unableToPing
    }

    private let verificationURL: URL
    private let registrationURL: URL

    init?(host: String = "nos.social") {
        let verificationURLString = "https://\(host)/.well-known/nostr.json"
        guard let verificationURL = URL(string: verificationURLString) else {
            return nil
        }
        let registrationURLString = "https://\(host)/api/names"
        guard let registrationURL = URL(string: registrationURLString) else {
            return nil
        }
        self.verificationURL = verificationURL
        self.registrationURL = registrationURL
        self.urlCache.removeAllCachedResponses()
    }

    /// Deletes a given username from `nos.social`
    func delete(
        username: String,
        keyPair: KeyPair
    ) async throws {
        let request = try buildURLRequest(
            url: registrationURL.appending(path: username),
            method: .delete,
            json: try buildJSON(username: username, keyPair: keyPair),
            keyPair: keyPair
        )
        let (_, response) = try await URLSession.shared.data(for: request)
        if let response = response as? HTTPURLResponse {
            if response.statusCode == 200 {
                return
            }
        }
        throw Error.unexpected
    }

    /// Verifies that a given username is free to claim in nos.social, or has
    /// already been claimed by the given `publicKey`.
    func checkAvailability(
        username: String,
        publicKey: PublicKey
    ) async throws -> Bool {
        let result = try await ping(
            username: username,
            host: verificationURL,
            publicKey: publicKey
        )
        return result == .match || result == .notFound
    }

    /// Verifies that a given NIP-05 username is properly connected to the
    /// public key.
    func verify(
        username: String,
        publicKey: PublicKey
    ) async throws -> Bool {
        let components = username.components(separatedBy: "@")

        guard components.count == 2 else {
            return false
        }

        let localPart = components[0]
        let domain = components[1]

        let hostString = "https://\(domain)/.well-known/nostr.json"
        guard let host = URL(string: hostString) else {
            return false
        }

        let result = try await ping(
            username: localPart,
            host: host,
            publicKey: publicKey,
            shouldUseCache: false
        )
        return result == .match
    }

    /// Registers a given username at `nos.social`
    func register(
        username: String,
        keyPair: KeyPair,
        relays: [URL]
    ) async throws {
        let request = try buildURLRequest(
            url: registrationURL,
            method: .post,
            json: try buildJSON(
                username: username,
                keyPair: keyPair,
                relays: relays
            ),
            keyPair: keyPair
        )
        let (_, response) = try await URLSession.shared.data(for: request)
        if let response = response as? HTTPURLResponse {
            if response.statusCode == 200 {
                return
            } else {
                throw Error.usernameNotAvailable
            }
        }
        throw Error.unexpected
    }

    /// Makes a request to `/.well-known/nostr.json` at the host with the
    /// provided username and matches the server result with the provided public
    /// key.
    private func ping(
        username: String,
        host: URL,
        publicKey: PublicKey,
        shouldUseCache: Bool = true
    ) async throws -> PingResult {
        let request = URLRequest(
            url: host.appending(
                queryItems: [URLQueryItem(name: "name", value: username)]
            )
        )
        let (data, response): (Data, URLResponse)
        if shouldUseCache, let cached = urlCache.cachedResponse(for: request) {
            data = cached.data
            response = cached.response
        } else {
            (data, response) = try await session.data(for: request)
        }

        if let response = response as? HTTPURLResponse {
            let statusCode = response.statusCode
            if statusCode == 404 {
                return .notFound
            } else if statusCode == 200 {
                let jsonObject = try JSONSerialization.jsonObject(with: data)
                if let json = jsonObject as? [String: Any] {
                    if shouldUseCache, data.count < maximumURLCacheItemSize {
                        let cachedResponse = CachedURLResponse(
                            response: response,
                            data: data
                        )
                        urlCache.storeCachedResponse(
                            cachedResponse,
                            for: request
                        )
                    }
                    let names = json["names"] as? [String: String]
                    let npub = names?[username]
                    if npub == publicKey.hex {
                        return .match
                    } else {
                        return .mismatch
                    }
                }
            }
        }
        return .unableToPing
    }

    private func buildURLRequest(
        url: URL,
        method: HTTPMethod,
        json: Data?,
        keyPair: KeyPair
    ) throws -> URLRequest {
        let content = ""
        let tags = [
            ["u", url.absoluteString],
            ["method", method.rawValue]
        ]
        var jsonEvent = JSONEvent(
            pubKey: keyPair.publicKeyHex,
            kind: .httpAuth,
            tags: tags,
            content: content
        )
        try jsonEvent.sign(withKey: keyPair)
        let jsonObject = jsonEvent.dictionary
        let requestData = try JSONSerialization.data(withJSONObject: jsonObject)
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue(
            "Nostr \(requestData.base64EncodedString())",
            forHTTPHeaderField: "Authorization"
        )
        if let json {
            request.setValue(
                "application/json",
                forHTTPHeaderField: "Content-Type"
            )
            request.httpBody = json
        }
        return request
    }

    private func buildJSON(
        username: String,
        keyPair: KeyPair,
        relays: [URL] = []
    ) throws -> Data {
        try JSONSerialization.data(
            withJSONObject: [
                "name": username,
                "data": [
                    "pubkey": keyPair.publicKeyHex,
                    "relays": relays.map { $0.absoluteString }
                ]
            ]
        )
    }
}
