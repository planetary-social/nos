import Dependencies
import XCTest

class NostrBuildAPIClientTests: XCTestCase {
    func test_fetchMetadata_success() async throws {
        // Arrange
        let subject = try withDependencies {
            let data = try jsonData(filename: "nostr_build_nip96_response")
            $0.urlSession = MockURLSession(responseData: data)
        } operation: {
            NostrBuildAPIClient()
        }

        // Act
        let metadataResponse = try await subject.fetchMetadata()

        // Assert
        XCTAssertEqual(metadataResponse.apiUrl, "https://nostr.build/api/v2/nip96/upload")
    }

    func test_fetchMetadata_throws_decoding_error_when_API_returns_unexpected_data() async throws {
        // Arrange
        let subject = withDependencies {
            $0.urlSession = MockURLSession()
        } operation: {
            NostrBuildAPIClient()
        }

        // Act & Assert
        do {
            _ = try await subject.fetchMetadata()
        } catch {
            let result = try XCTUnwrap(error as? FileStorageAPIClientError)
            XCTAssertEqual(result, FileStorageAPIClientError.decodingError)
        }
    }
}
