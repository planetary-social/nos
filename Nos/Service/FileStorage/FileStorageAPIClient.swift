import Dependencies
import Foundation
import Logger

/// A client for a File Storage API, as defined in [NIP-96](https://github.com/nostr-protocol/nips/blob/master/96.md)
protocol FileStorageAPIClient {
    /// Fetches and caches server info for the file storage API.
    func refreshServerInfo()

    /// Uploads the file at the given URL.
    func upload(fileAt fileURL: URL) async throws -> URL
}

enum FileStorageAPIClientError: Error {
    case decodingError
    case invalidURLRequest
    case uploadError
}

class NostrBuildAPIClient: FileStorageAPIClient {
    @Dependency(\.urlSession) var urlSession

    private static let serverInfoURLString = "https://nostr.build/.well-known/nostr/nip96.json"

    private var serverInfo: FileStorageServerInfoResponseJSON?

    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }

    // MARK: - FileStorageAPIClient protocol

    func refreshServerInfo() {
        Task {
            do {
                serverInfo = try await fetchServerInfo()
                Log.debug("Refreshed file storage server info cache with data: \(String(describing: serverInfo))")
            } catch {
                Log.debug("Error refreshing file storage server info cache: \(error)")
            }
        }
    }

    func upload(fileAt fileURL: URL) async throws -> URL {
        guard let serverInfo,
            let url = URL(string: serverInfo.apiUrl) else {
            throw FileStorageAPIClientError.uploadError
        }
        return url
    }

    // MARK: - Internal

    /// Fetches server info from the file storage API.
    /// - Returns: the decoded JSON containing server info for the file storage API.
    func fetchServerInfo() async throws -> FileStorageServerInfoResponseJSON {
        guard let url = URL(string: Self.serverInfoURLString) else {
            throw FileStorageAPIClientError.invalidURLRequest
        }

        let urlRequest = URLRequest(url: url)
        let (responseData, _) = try await urlSession.data(for: urlRequest)
        do {
            return try decoder.decode(FileStorageServerInfoResponseJSON.self, from: responseData)
        } catch {
            throw FileStorageAPIClientError.decodingError
        }
    }
}
