import Dependencies
import Foundation

protocol FileStorageAPIClient {
    func fetchMetadata() async throws -> FileStorageMetadataResponseJSON
}

enum FileStorageAPIClientError: Error {
    case decodingError
    case invalidURLRequest
}

struct NostrBuildAPIClient: FileStorageAPIClient {
    @Dependency(\.urlSession) var urlSession
    @Dependency(\.fileStorageResponseDecoder) var decoder

    func fetchMetadata() async throws -> FileStorageMetadataResponseJSON {
        guard let urlRequest = FileStorageAPIRequest.serverInfo.urlRequest else {
            throw FileStorageAPIClientError.invalidURLRequest
        }

        let (responseData, _) = try await urlSession.data(for: urlRequest)
        do {
            return try decoder.decode(FileStorageMetadataResponseJSON.self, from: responseData)
        } catch {
            throw FileStorageAPIClientError.decodingError
        }
    }
}
