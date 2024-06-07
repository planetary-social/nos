import XCTest

class FileStorageUploadResponseJSONTests: XCTestCase {
    /// Verifies that we can properly decode a response from the File Storage metadata API endpoint.
    func test_decode() throws {
        // Arrange
        let jsonData = try jsonData(filename: "nostr_build_nip96_upload_response")
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        // Act
        let subject = try decoder.decode(FileStorageUploadResponseJSON.self, from: jsonData)

        // Assert
        XCTAssertEqual(
            subject.nip94Event?.urlString,
            "https://image.nostr.build/02361b65063679d9d2dda1eedbfa49f1f345d22f12201bc6367b79d7c5443f22.jpeg"
        )
    }
}
