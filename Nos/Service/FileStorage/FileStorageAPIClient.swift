import Dependencies
import Foundation

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
