import XCTest

class NostrBuildResponseJSONTests: XCTestCase {
    /// Verifies that we can properly decode a response from the nostr.build API.
    func test_decode() throws {
        // Arrange
        let jsonData = try jsonData(filename: "nostr_build_api_v2_response")
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        // Act
        let subject = try decoder.decode(NostrBuildResponseJSON.self, from: jsonData)

        // Assert
        XCTAssertEqual(subject.status, .success)
        XCTAssertEqual(subject.message, "Upload successful.")

        let photo = try XCTUnwrap(subject.data?.first)
        XCTAssertEqual(
            photo.url,
            "https://image.nostr.build/d9a71e94e59ab36ce13dd6998dcdb34527acdd2781cb6b91858ea0a8ca8557b1.jpeg"
        )
        XCTAssertEqual(
            photo.thumbnail,
            "https://image.nostr.build/thumb/d9a71e94e59ab36ce13dd6998dcdb34527acdd2781cb6b91858ea0a8ca8557b1.jpeg"
        )
        XCTAssertEqual(photo.mime, "image/jpeg")
        XCTAssertEqual(photo.type, "picture")
    }
}
