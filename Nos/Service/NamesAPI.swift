import Foundation

/// The NamesAPI service is in charge of creating and deleting nos.social usernames and
/// verifying if a NIP-05 or nos.social username can be associated or not.
class NamesAPI {

    private enum Error: LocalizedError {
        case unexpected
        case usernameNotAvailable

        var errorDescription: String? {
            switch self {
            case .unexpected:
                return "Unexpected"
            case .usernameNotAvailable:
                return String(localized: .localizable.usernameAlreadyClaimed)
            }
        }
    }

    private enum HTTPMethod: String {
        case delete = "DELETE"
        case post = "POST"
    }

    private let verificationURL: URL
    private let registrationURL: URL

    init?(host: String = "nos.social") {
        guard let verificationURL = URL(string: "https://\(host)/.well-known/nostr.json") else {
            return nil
        }
        guard let registrationURL = URL(string: "https://\(host)/api/names") else {
            return nil
        }
        self.verificationURL = verificationURL
        self.registrationURL = registrationURL
    }

    func delete(username: String, keyPair: KeyPair) async throws {
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

    /// Verifies that a given username is free to claim in nos.social
    func verify(username: String, keyPair: KeyPair) async throws -> Bool {
        try await verify(
            username: username,
            host: verificationURL,
            keyPair: keyPair,
            valueWhenNotFound: true
        )
    }

    /// Verifies that a given username_at_host NIP-05 can be connected to the keyPair
    ///
    /// - Parameter valueWhenNotFound: What to return if the server returns 404
    func verify(
        username: String,
        host: URL,
        keyPair: KeyPair,
        valueWhenNotFound: Bool = false
    ) async throws -> Bool {
        let request = URLRequest(
            url: host.appending(queryItems: [URLQueryItem(name: "name", value: username)])
        )
        let (data, response) = try await URLSession.shared.data(for: request)
        if let response = response as? HTTPURLResponse {
            let statusCode = response.statusCode
            if statusCode == 404 {
                return valueWhenNotFound
            } else if statusCode == 200, let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let names = json["names"] as? [String: String]
                let npub = names?[username]
                return npub == keyPair.publicKeyHex
            }
        }
        return false
    }

    func register(username: String, keyPair: KeyPair) async throws {
        let request = try buildURLRequest(
            url: registrationURL,
            method: .post,
            json: try buildJSON(username: username, keyPair: keyPair),
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

    private func buildURLRequest(url: URL, method: HTTPMethod, json: Data?, keyPair: KeyPair) throws -> URLRequest {
        let content = ""
        let tags = [["u", url.absoluteString], ["method", method.rawValue]]
        var jsonEvent = JSONEvent(pubKey: keyPair.publicKeyHex, kind: .auth, tags: tags, content: content)
        try jsonEvent.sign(withKey: keyPair)
        let requestData = try JSONSerialization.data(withJSONObject: jsonEvent.dictionary)
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("Nostr \(requestData.base64EncodedString())", forHTTPHeaderField: "Authorization")
        if let json {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = json
        }
        return request
    }

    private func buildJSON(username: String, keyPair: KeyPair) throws -> Data {
        try JSONSerialization.data(
            withJSONObject: ["name": username, "data": ["pubkey": keyPair.publicKeyHex]]
        )
    }
}
