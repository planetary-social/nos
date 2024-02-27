//
//  NamesAPI.swift
//  Nos
//
//  Created by Martin Dutra on 21/2/24.
//

import Foundation

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

    let verificationURL: URL
    let registrationURL: URL

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
        let httpMethod = HTTPMethod.delete
        let url = registrationURL.appending(path: username)
        let content = ""
        let tags = [["u", url.absoluteString], ["method", httpMethod.rawValue]]
        var jsonEvent = JSONEvent(pubKey: keyPair.publicKeyHex, kind: .auth, tags: tags, content: content)
        try jsonEvent.sign(withKey: keyPair)
        let requestData = try JSONSerialization.data(withJSONObject: jsonEvent.dictionary)
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod.rawValue
        request.setValue("Nostr \(requestData.base64EncodedString())", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(
            withJSONObject: ["name": username, "data": ["pubkey": keyPair.publicKeyHex]]
        )
        let (_, response) = try await URLSession.shared.data(for: request)
        if let response = response as? HTTPURLResponse {
            if response.statusCode == 200 {
                return
            }
        }
        throw Error.unexpected
    }

    func verify(username: String) async throws -> Bool {
        let request = URLRequest(
            url: verificationURL.appending(queryItems: [URLQueryItem(name: "name", value: username)])
        )
        let (_, response) = try await URLSession.shared.data(for: request)
        if let response = response as? HTTPURLResponse {
            return response.statusCode == 404
        } else {
            return false
        }
    }

    func register(username: String, keyPair: KeyPair) async throws {
        let httpMethod = HTTPMethod.post
        let content = ""
        let tags = [["u", registrationURL.absoluteString], ["method", httpMethod.rawValue]]
        var jsonEvent = JSONEvent(pubKey: keyPair.publicKeyHex, kind: .auth, tags: tags, content: content)
        try jsonEvent.sign(withKey: keyPair)
        let requestData = try JSONSerialization.data(withJSONObject: jsonEvent.dictionary)
        var request = URLRequest(url: registrationURL)
        request.httpMethod = httpMethod.rawValue
        request.setValue("Nostr \(requestData.base64EncodedString())", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(
            withJSONObject: ["name": username, "data": ["pubkey": keyPair.publicKeyHex]]
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
}
