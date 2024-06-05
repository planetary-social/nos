import XCTest

class FileStorageServerInfoResponseJSONTests: XCTestCase {
    /// Verifies that we can properly decode a response from the File Storage metadata API endpoint.
    func test_decode() throws {
        // Arrange
        let jsonData = try jsonData(filename: "nostr_build_nip96_response")
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        // Act
        let subject = try decoder.decode(FileStorageServerInfoResponseJSON.self, from: jsonData)

        // Assert
        XCTAssertEqual(subject.apiUrl, "https://nostr.build/api/v2/nip96/upload")
    }
}
