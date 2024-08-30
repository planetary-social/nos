import XCTest

extension EventProcessorIntegrationTests {
    @MainActor func test_parse_gets_inline_metadata() throws {
        // Arrange
        let jsonData = try jsonData(filename: "text_note_with_media_metadata")
        let jsonEvent = try JSONDecoder().decode(JSONEvent.self, from: jsonData)

        // Act
        let parsedEvent = try XCTUnwrap(
            try EventProcessor.parse(jsonEvent: jsonEvent, from: nil, in: testContext, skipVerification: true)
        )

        // Assert
        let inlineMetadata = try XCTUnwrap(parsedEvent.inlineMetadata)
        XCTAssertEqual(
            inlineMetadata.url,
            "https://image.nostr.build/6ffcd8dadcdf7a54a7f3d7bafb958d4d21040820b479db1047135d0cbfd24a95.png"
        )
        XCTAssertEqual(inlineMetadata.dimensions, CGSize(width: 746, height: 443))
    }
}
