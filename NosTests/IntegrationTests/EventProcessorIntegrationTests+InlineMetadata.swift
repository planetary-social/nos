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

        let url = "https://image.nostr.build/6ffcd8dadcdf7a54a7f3d7bafb958d4d21040820b479db1047135d0cbfd24a95.png"
        let inlineMetadataTag = try XCTUnwrap(parsedEvent.inlineMetadata?[url])
        XCTAssertEqual(inlineMetadataTag.url, url)
        XCTAssertEqual(inlineMetadataTag.dimensions, CGSize(width: 746, height: 443))
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

        let squareImageURL =
            "https://image.nostr.build/70f1f360919cbc044cfca6cc0d0ba1a420632c4828f7d22082d3463f33f06d7b.jpg"
        let squareImageMetadata = try XCTUnwrap(inlineMetadata[squareImageURL])
        XCTAssertEqual(squareImageMetadata.dimensions, CGSize(width: 854, height: 854))
        XCTAssertEqual(squareImageMetadata.orientation, .landscape)

        let portraitImageURL = 
            "https://image.nostr.build/2787ad495941dfb068fbff77f087513095a3f981f9697fcb9e51c052c6198090.jpg"
        let portraitImageMetadata = try XCTUnwrap(inlineMetadata[portraitImageURL])
        XCTAssertEqual(portraitImageMetadata.dimensions, CGSize(width: 1263, height: 3985))
        XCTAssertEqual(portraitImageMetadata.orientation, .portrait)
    }

    @MainActor func test_parse_with_duplicate_inline_metadata_urls_uses_the_first_and_continues() throws {
        // Arrange
        let jsonData = try jsonData(filename: "text_note_with_duplicate_metadata_urls")
        let jsonEvent = try JSONDecoder().decode(JSONEvent.self, from: jsonData)

        // Act
        let parsedEvent = try XCTUnwrap(
            try EventProcessor.parse(jsonEvent: jsonEvent, from: nil, in: testContext, skipVerification: true)
        )

        let inlineMetadata = try XCTUnwrap(parsedEvent.inlineMetadata)

        let portraitImageURL =
            "https://image.nostr.build/2787ad495941dfb068fbff77f087513095a3f981f9697fcb9e51c052c6198090.jpg"
        let portraitMetadataTag = try XCTUnwrap(inlineMetadata[portraitImageURL])
        XCTAssertEqual(portraitMetadataTag.url, portraitImageURL)
        XCTAssertEqual(portraitMetadataTag.dimensions, CGSize(width: 1263, height: 3985))

        let squareImageURL =
            "https://image.nostr.build/70f1f360919cbc044cfca6cc0d0ba1a420632c4828f7d22082d3463f33f06d7b.jpg"
        let squareMetadataTag = try XCTUnwrap(inlineMetadata[squareImageURL])
        XCTAssertEqual(squareMetadataTag.url, squareImageURL)
        XCTAssertEqual(squareMetadataTag.dimensions, CGSize(width: 854, height: 854))
    }
}
