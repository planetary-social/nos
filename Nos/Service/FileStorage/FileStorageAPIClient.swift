import Dependencies
import Foundation
import Logger

/// A client for a File Storage API, as defined in [NIP-96](https://github.com/nostr-protocol/nips/blob/master/96.md)
protocol FileStorageAPIClient {
    /// Fetches and caches server info for the file storage API, such as the API URL for uploading.
    func refreshServerInfo()
    func upload(fileAt fileURL: URL) async throws -> URL
}

enum FileStorageAPIClientError: Error {
    case decodingError
    case invalidURLRequest
    case uploadError
}

class NostrBuildAPIClient: FileStorageAPIClient {
    @Dependency(\.urlSession) var urlSession
    @Dependency(\.fileStorageResponseDecoder) var decoder

    private var serverInfo: FileStorageServerInfoResponseJSON?

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
        guard let url = URL(string: "http://google.com") else {
            throw FileStorageAPIClientError.uploadError
        }
        return url
    }

    // MARK: - Private

    /// Fetches server info from the file storage API.
    /// - Returns: the decoded JSON containing server info for the file storage API.
    private func fetchServerInfo() async throws -> FileStorageServerInfoResponseJSON {
        guard let urlRequest = FileStorageAPIRequest.serverInfo.urlRequest else {
            throw FileStorageAPIClientError.invalidURLRequest
        }

        let (responseData, _) = try await urlSession.data(for: urlRequest)
        do {
            return try decoder.decode(FileStorageServerInfoResponseJSON.self, from: responseData)
        } catch {
            throw FileStorageAPIClientError.decodingError
        }
    }
}
