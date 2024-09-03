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
        let inlineMetadata = try XCTUnwrap(parsedEvent.inlineMetadata.first)
        XCTAssertEqual(
            inlineMetadata.url,
            "https://image.nostr.build/6ffcd8dadcdf7a54a7f3d7bafb958d4d21040820b479db1047135d0cbfd24a95.png"
        )
        XCTAssertEqual(inlineMetadata.dimensions, CGSize(width: 746, height: 443))
    }

    @MainActor func test_parse_multiple_inline_metadata() throws {
        // Arrange
        let jsonData = try jsonData(filename: "text_note_multiple_media")
        let jsonEvent = try JSONDecoder().decode(JSONEvent.self, from: jsonData)

        // Act
        let parsedEvent = try XCTUnwrap(
            try EventProcessor.parse(jsonEvent: jsonEvent, from: nil, in: testContext, skipVerification: true)
        )

        // Assert
        let inlineMetadata = try XCTUnwrap(parsedEvent.inlineMetadata)

        let squareImageMetadata = try XCTUnwrap(inlineMetadata.first(where: {
            $0.url == "https://image.nostr.build/70f1f360919cbc044cfca6cc0d0ba1a420632c4828f7d22082d3463f33f06d7b.jpg"
        }))
        XCTAssertEqual(squareImageMetadata.dimensions, CGSize(width: 854, height: 854))
    }
}
