import Dependencies
import Foundation
import Logger

protocol FileStorageAPIClient {
    func fetchServerInfo() async throws -> FileStorageServerInfoResponseJSON
}

enum FileStorageAPIClientError: Error {
    case decodingError
    case invalidURLRequest
}

struct NostrBuildAPIClient: FileStorageAPIClient {
    @Dependency(\.urlSession) var urlSession
    @Dependency(\.fileStorageResponseDecoder) var decoder

    /// Fetches server info from the file storage API to determine the API URL.
    func fetchServerInfo() async throws -> FileStorageServerInfoResponseJSON {
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

protocol FileStorageServerInfoCache {
    /// Refreshes the cached server info.
    func refreshCache()
}

class DefaultFileStorageServerInfoCache: FileStorageServerInfoCache {
    @Dependency(\.fileStorageAPIClient) private var fileStorageAPIClient

    var serverInfo: FileStorageServerInfoResponseJSON?

    func refreshCache() {
        Task {
            do {
                serverInfo = try await fileStorageAPIClient.fetchServerInfo()
                Log.debug("Refreshed file storage server info cache with data: \(String(describing: serverInfo))")
            } catch {
                Log.debug("Error refreshing file storage server info cache: \(error)")
            }
        }
    }
}
