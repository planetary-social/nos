import XCTest

extension NoteParserTests {
    @MainActor func testContentWithNIP08Mention() throws {
        let name = "mattn"
        let content = "hello #[0]"
        let hex = "2c7cc62a697ea3a7826521f3fd34f0cb273693cbe5e9310f35449f43622a5cdc"
        let expectedContent = "hello @\(name)"
        let tags = [["p", hex]]
        let author = try Author.findOrCreate(by: hex, context: testContext)
        author.displayName = name
        try testContext.save()
        let components = sut.components(
            in: content,
            tags: tags,
            context: testContext
        )
        let attributedContent = components.attributedContent
        let parsedContent = String(attributedContent.characters)
        XCTAssertEqual(parsedContent, expectedContent)
        let links = attributedContent.links
        XCTAssertEqual(links.count, 1)
        XCTAssertEqual(links.first?.key, "@\(name)")
        XCTAssertEqual(links.first?.value, URL(string: "@\(hex)"))
    }

    func testContentWithNIP08MentionToUnknownAuthor() async throws {
        let content = "hello #[0]"
        let displayName = "npub1937vv..."
        let hex = "2c7cc62a697ea3a7826521f3fd34f0cb273693cbe5e9310f35449f43622a5cdc"
        let expectedContent = "hello @\(displayName)"
        let tags = [["p", hex]]
        let context = persistenceController.viewContext
        let components = sut.components(
            in: content,
            tags: tags,
            context: context
        )
        let attributedContent = components.attributedContent
        let parsedContent = String(attributedContent.characters)
        XCTAssertEqual(parsedContent, expectedContent)
        let links = attributedContent.links
        XCTAssertEqual(links.count, 1)
        XCTAssertEqual(links.first?.key, "@\(displayName)")
        XCTAssertEqual(links.first?.value, URL(string: "@\(hex)"))
    }

    @MainActor func testContentWithNIP08MentionAtBeginning() throws {
        let content = "#[0]"
        let displayName = "npub1937vv..."
        let hex = "2c7cc62a697ea3a7826521f3fd34f0cb273693cbe5e9310f35449f43622a5cdc"
        let expectedContent = "@\(displayName)"
        let tags = [["p", hex]]
        let components = sut.components(
            in: content,
            tags: tags,
            context: testContext
        )
        let attributedContent = components.attributedContent
        let parsedContent = String(attributedContent.characters)
        XCTAssertEqual(parsedContent, expectedContent)
        let links = attributedContent.links
        XCTAssertEqual(links.count, 1)
        XCTAssertEqual(links.first?.key, "@\(displayName)")
        XCTAssertEqual(links.first?.value, URL(string: "@\(hex)"))
    }

    @MainActor func testContentWithNIP08MentionAfterNewline() throws {
        let content = "Hello\n#[0]"
        let displayName = "npub1937vv..."
        let hex = "2c7cc62a697ea3a7826521f3fd34f0cb273693cbe5e9310f35449f43622a5cdc"
        let expectedContent = "Hello\n@\(displayName)"
        let tags = [["p", hex]]
        let components = sut.components(
            in: content,
            tags: tags,
            context: testContext
        )
        let attributedContent = components.attributedContent
        let parsedContent = String(attributedContent.characters)
        XCTAssertEqual(parsedContent, expectedContent)
        let links = attributedContent.links
        XCTAssertEqual(links.count, 1)
        XCTAssertEqual(links.first?.key, "@\(displayName)")
        XCTAssertEqual(links.first?.value, URL(string: "@\(hex)"))
    }

    @MainActor func testContentWithNIP08MentionInsideAWord() throws {
        let content = "hello#[0]"
        let hex = "2c7cc62a697ea3a7826521f3fd34f0cb273693cbe5e9310f35449f43622a5cdc"
        let expectedContent = "hello#[0]"
        let tags = [["p", hex]]
        let components = sut.components(
            in: content,
            tags: tags,
            context: testContext
        )
        let attributedContent = components.attributedContent
        let parsedContent = String(attributedContent.characters)
        XCTAssertEqual(parsedContent, expectedContent)
        let links = attributedContent.links
        XCTAssertEqual(links.count, 0)
    }
}
