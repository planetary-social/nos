import Dependencies
import XCTest

class NostrBuildAPIClientTests: XCTestCase {
    func test_fetchServerInfo_success() async throws {
        // Arrange
        let subject = try withDependencies {
            let data = try jsonData(filename: "nostr_build_nip96_response")
            $0.urlSession = MockURLSession(responseData: data)
        } operation: {
            NostrBuildAPIClient()
        }

        // Act
        let metadataResponse = try await subject.fetchServerInfo()

        // Assert
        XCTAssertEqual(metadataResponse.apiUrl, "https://nostr.build/api/v2/nip96/upload")
    }

    func test_fetchServerInfo_throws_decoding_error_when_API_returns_unexpected_data() async throws {
        // Arrange
        let subject = withDependencies {
            $0.urlSession = MockURLSession()
        } operation: {
            NostrBuildAPIClient()
        }

        // Act & Assert
        do {
            _ = try await subject.fetchServerInfo()
            XCTFail("Expected an error to be thrown")
        } catch {
            switch error {
            case FileStorageAPIClientError.decodingError: 
                break
            default:
                XCTFail("Expected a decodingError but got \(error)")
            }
        }
    }

    func test_uploadRequest_properties() throws {
        // Arrange
        let subject = NostrBuildAPIClient()
        let apiURLString = "http://nostr.build/api/v2/nip96/upload"
        subject.serverInfo = FileStorageServerInfoResponseJSON(apiUrl: apiURLString)
        let fileURL = try XCTUnwrap(Bundle.current.url(forResource: "nostr_build_response", withExtension: "json"))

        // Act
        let (uploadRequest, _) = try subject.uploadRequest(fileAt: fileURL)

        // Assert
        XCTAssertEqual(uploadRequest.httpMethod, "POST")
        XCTAssertEqual(uploadRequest.url?.absoluteString, apiURLString)
    }

    func test_uploadRequest_throws_error_when_no_serverInfo() throws {
        // Arrange
        let subject = NostrBuildAPIClient()
        let fileURL = try XCTUnwrap(Bundle.current.url(forResource: "nostr_build_response", withExtension: "json"))

        // Act & Assert
        XCTAssertThrowsError(try subject.uploadRequest(fileAt: fileURL))
    }
}
