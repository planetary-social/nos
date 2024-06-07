import XCTest

class FileStorageAPIRequestTests: XCTestCase {
    func test_metadata_request() throws {
        // Arrange
        let subject = FileStorageAPIRequest.serverInfo

        // Act
        let urlRequest = try XCTUnwrap(subject.urlRequest)

        // Assert
        XCTAssertEqual(urlRequest.httpMethod, "GET")

        let url = try XCTUnwrap(urlRequest.url)
        XCTAssertEqual(url.absoluteString, "https://nostr.build/.well-known/nostr/nip96.json")
    }
}
