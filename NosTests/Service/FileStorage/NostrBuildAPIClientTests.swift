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

    func test_upload_throws_error_when_serverInfo_has_invalid_apiUrl() async throws {
        // Arrange
        let subject = NostrBuildAPIClient()
        subject.serverInfo = FileStorageServerInfoResponseJSON(apiUrl: "")
        let fileURL = try XCTUnwrap(
            Bundle.current.url(forResource: "nostr_build_nip96_response", withExtension: "json")
        )

        // Act & Assert
        do {
            _ = try await subject.upload(fileAt: fileURL)
            XCTFail("Expected an error to be thrown")
        } catch {
            switch error {
            case FileStorageAPIClientError.invalidURLRequest:
                break
            default:
                XCTFail("Expected an invalidURLRequest error but got \(error)")
            }
        }
    }

    func test_uploadRequest_authorization_header() async throws {
        // Arrange
        let subject = await withDependencies {
            await $0.currentUser.setKeyPair(KeyFixture.alice)
        } operation: {
            NostrBuildAPIClient()
        }

        let apiURLString = "https://nostr.build/api/v2/nip96/upload"
        let apiURL = try XCTUnwrap(URL(string: apiURLString))

        let fileURL = try XCTUnwrap(
            Bundle.current.url(forResource: "nostr_build_nip96_response", withExtension: "json")
        )

        // Act
        let (uploadRequest, _) = try subject.uploadRequest(fileAt: fileURL, apiURL: apiURL)

        // Assert
        let authHeader = try XCTUnwrap(uploadRequest.value(forHTTPHeaderField: "Authorization"))
        XCTAssertTrue(authHeader.hasPrefix("Nostr eyJ"))
    }

    func test_uploadRequest_properties() async throws {
        // Arrange
        let subject = await withDependencies {
            await $0.currentUser.setKeyPair(KeyFixture.alice)
        } operation: {
            NostrBuildAPIClient()
        }

        let apiURLString = "http://nostr.build/api/v2/nip96/upload"
        let apiURL = try XCTUnwrap(URL(string: apiURLString))
        let fileURL = try XCTUnwrap(
            Bundle.current.url(forResource: "nostr_build_nip96_response", withExtension: "json")
        )

        // Act
        let (uploadRequest, _) = try subject.uploadRequest(fileAt: fileURL, apiURL: apiURL)

        // Assert
        XCTAssertEqual(uploadRequest.httpMethod, "POST")
        XCTAssertEqual(uploadRequest.url?.absoluteString, apiURLString)
    }
}
