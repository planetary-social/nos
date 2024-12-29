import XCTest

extension EventProcessorIntegrationTests {
    @MainActor func test_parse_kind_30000_creates_follow_set() throws {
        // Arrange
        let replaceableID = "listr-7ad818d7-1360-4fcb-8dbd-2ad76be88465"
        let ownerPubKey = "27cf2c68535ae1fc06510e827670053f5dcd39e6bd7e05f1ffb487ef2ac13549"
        let jsonData = try jsonData(filename: "follow_set")
        let jsonEvent = try JSONDecoder().decode(JSONEvent.self, from: jsonData)

        // Act
        _ = try EventProcessor.parse(jsonEvent: jsonEvent, from: nil, in: testContext, skipVerification: true)

        // Assert
        let fetchResults = try testContext.fetch(
            AuthorList.authorList(
                by: replaceableID,
                owner: try Author.findOrCreate(by: ownerPubKey, context: testContext),
                kind: EventKind.followSet.rawValue
            )
        )
        XCTAssertEqual(fetchResults.count, 1)

        let followSet = try XCTUnwrap(fetchResults.first)
        // swiftlint:disable:next number_separator
        XCTAssertEqual(followSet.createdAt, Date(timeIntervalSince1970: 1733516879))
        XCTAssertEqual(followSet.replaceableIdentifier, replaceableID)
        XCTAssertEqual(followSet.title, "A few good people")
        XCTAssertEqual(followSet.listDescription, "They're great. Trust me.")
        XCTAssertEqual(followSet.authors.count, 2)

        let authorPubKeys = followSet.authors.map { $0.hexadecimalPublicKey }
        XCTAssertTrue(authorPubKeys.contains(
            where: { $0 == "27cf2c68535ae1fc06510e827670053f5dcd39e6bd7e05f1ffb487ef2ac13549" }
        ))
        XCTAssertTrue(authorPubKeys.contains(
            where: { $0 == "1112cad6ffadb22c4d505e9b9f53322052e05a834822cf9368dc754cabbc7ba9" }
        ))
    }

    @MainActor func test_parse_kind_30000_updates_existing_follow_set() throws {
        // Arrange
        let replaceableID = "listr-7ad818d7-1360-4fcb-8dbd-2ad76be88465"
        let ownerPubKey = "27cf2c68535ae1fc06510e827670053f5dcd39e6bd7e05f1ffb487ef2ac13549"
        let data = try jsonData(filename: "follow_set")
        let jsonEvent = try JSONDecoder().decode(JSONEvent.self, from: data)

        // Act
        _ = try EventProcessor.parse(jsonEvent: jsonEvent, from: nil, in: testContext, skipVerification: true)
        let updatedJsonData = try jsonData(filename: "follow_set_updated")
        let updatedJsonEvent = try JSONDecoder().decode(JSONEvent.self, from: updatedJsonData)
        _ = try EventProcessor.parse(jsonEvent: updatedJsonEvent, from: nil, in: testContext, skipVerification: true)

        // Assert
        let fetchResults = try testContext.fetch(
            AuthorList.authorList(
                by: replaceableID,
                owner: try Author.findOrCreate(by: ownerPubKey, context: testContext),
                kind: EventKind.followSet.rawValue
            )
        )
        XCTAssertEqual(fetchResults.count, 1)

        let followSet = try XCTUnwrap(fetchResults.first)

        // swiftlint:disable:next number_separator
        XCTAssertEqual(followSet.createdAt, Date(timeIntervalSince1970: 1733765380))
        XCTAssertEqual(followSet.replaceableIdentifier, replaceableID)
        XCTAssertEqual(followSet.title, "A few good people")
        XCTAssertEqual(followSet.listDescription, "They're great. Trust me.")
        XCTAssertEqual(followSet.authors.count, 1)

        let authorPubKey = try XCTUnwrap(followSet.authors.first?.hexadecimalPublicKey)
        XCTAssertEqual(authorPubKey, "27cf2c68535ae1fc06510e827670053f5dcd39e6bd7e05f1ffb487ef2ac13549")
    }
    
    @MainActor func test_parse_kind_30000_with_private_tags() throws {
        // Arrange
        let replaceableID = "PrivateOnly"
        let ownerPubKey = "ffd99f9e545b53e3291dab4b8cd6d25d12b9973c40f02e1938c0891d62e38e57"
        let data = try jsonData(filename: "follow_set_private")
        let jsonEvent = try JSONDecoder().decode(JSONEvent.self, from: data)

        // Act
        _ = try EventProcessor.parse(
            jsonEvent: jsonEvent,
            from: nil,
            in: testContext,
            skipVerification: true,
            keyPair: KeyPair(nsec: "nsec17vdaesh5tp6u5dy74vdy7a7e5x5ww4wfdnrn6ewgnsfxav8pcurqnlmj88")
        )

        // Assert
        let fetchResults = try testContext.fetch(
            AuthorList.authorList(
                by: replaceableID,
                owner: try Author.findOrCreate(by: ownerPubKey, context: testContext),
                kind: EventKind.followSet.rawValue
            )
        )
        XCTAssertEqual(fetchResults.count, 1)

        let followSet = try XCTUnwrap(fetchResults.first)
        XCTAssertTrue(followSet.authors.isEmpty)
        
        XCTAssertEqual(followSet.privateAuthors.count, 3)
        
        let publicKeys = followSet.privateAuthors.map { $0.hexadecimalPublicKey }
        XCTAssertTrue(publicKeys.contains("3efdaebb1d8923ebd99c9e7ace3b4194ab45512e2be79c1b7d68d9243e0d2681"))
        XCTAssertTrue(publicKeys.contains("3743244390be53473a7e3b3b8d04dce83f6c9514b81a997fb3b123c072ef9f78"))
        XCTAssertTrue(publicKeys.contains("fa984bd7dbb282f07e16e7ae87b26a2a7b9b90b7246a44771f0cf5ae58018f52"))
    }
}
