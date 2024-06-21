import XCTest

extension NoteParserTests {
    /// Example taken from [NIP-27](https://github.com/nostr-protocol/nips/blob/master/27.md)
    @MainActor func testContentWithNIP27Mention() throws {
        let name = "mattn"
        let content = "hello nostr:npub1937vv2nf06360qn9y8el6d8sevnndy7tuh5nzre4gj05xc32tnwqauhaj6"
        let hex = "2c7cc62a697ea3a7826521f3fd34f0cb273693cbe5e9310f35449f43622a5cdc"
        let tags = [["p", hex]]
        let author = try Author.findOrCreate(by: hex, context: testContext)
        author.displayName = name
        try testContext.save()
        let (attributedContent, _) = sut.parse(
            content: content,
            tags: tags,
            context: testContext
        )
        let links = attributedContent.links
        XCTAssertEqual(links.count, 1)
        XCTAssertEqual(links.first?.key, "@\(name)")
        XCTAssertEqual(links.first?.value, URL(string: "@\(hex)"))
    }

    /// Example taken from [NIP-27](https://github.com/nostr-protocol/nips/blob/master/27.md)
    @MainActor func testContentWithNIP27MentionToUnknownAuthor() throws {
        let displayName = "npub1937vv..."
        let content = "hello nostr:npub1937vv2nf06360qn9y8el6d8sevnndy7tuh5nzre4gj05xc32tnwqauhaj6"
        let hex = "2c7cc62a697ea3a7826521f3fd34f0cb273693cbe5e9310f35449f43622a5cdc"
        let tags = [["p", hex]]
        let (attributedContent, _) = sut.parse(
            content: content,
            tags: tags,
            context: testContext
        )
        let links = attributedContent.links
        XCTAssertEqual(links.count, 1)
        XCTAssertEqual(links.first?.key, "@\(displayName)")
        XCTAssertEqual(links.first?.value, URL(string: "@\(hex)"))
    }

    /// Example taken from [NIP-27](https://github.com/nostr-protocol/nips/blob/master/27.md)
    @MainActor func testContentWithNIP27ProfileMention() throws {
        let name = "mattn"
        let content = "hello nostr:nprofile1qqszclxx9f5haga8sfjjrulaxncvkfekj097t6f3pu65f86rvg49ehqj6f9dh"
        let hex = "2c7cc62a697ea3a7826521f3fd34f0cb273693cbe5e9310f35449f43622a5cdc"
        let tags = [["p", hex]]
        let author = try Author.findOrCreate(by: hex, context: testContext)
        author.displayName = name
        try testContext.save()
        let (attributedContent, _) = sut.parse(
            content: content,
            tags: tags,
            context: testContext
        )
        let links = attributedContent.links
        XCTAssertEqual(links.count, 1)
        XCTAssertEqual(links.first?.key, "@\(name)")
        XCTAssertEqual(links.first?.value, URL(string: "@\(hex)"))
    }

    @MainActor func testContentWithNIP27ProfileMentionWithADot() throws {
        let name = "mattn"
        let content = "Hello nostr:npub1pu3vqm4vzqpxsnhuc684dp2qaq6z69sf65yte4p39spcucv5lzmqswtfch.\n\nBye"
        let hex = "0f22c06eac1002684efcc68f568540e8342d1609d508bcd4312c038e6194f8b6"
        let tags = [["p", hex]]
        let author = try Author.findOrCreate(by: hex, context: testContext)
        author.displayName = name
        try testContext.save()
        let (attributedContent, _) = sut.parse(
            content: content,
            tags: tags,
            context: testContext
        )
        let links = attributedContent.links
        XCTAssertEqual(links.count, 1)
        XCTAssertEqual(links.first?.key, "@\(name)")
        XCTAssertEqual(links.first?.value, URL(string: "@\(hex)"))
    }

    @MainActor func testContentWithUntaggedNIP27NoteAndTaggedNIP27Profile() throws {
        let profileDisplayName = "@npub1pu3vq..."
        let profile = "npub1pu3vqm4vzqpxsnhuc684dp2qaq6z69sf65yte4p39spcucv5lzmqswtfch"
        let note = "note1h2mmqfjqle48j8ytmdar22v42g5y9n942aumyxatgtxpqj29pjjsjecraw"
        let content = "Check this nostr:\(note) from nostr:\(profile)"
        let profileHex = "0f22c06eac1002684efcc68f568540e8342d1609d508bcd4312c038e6194f8b6"
        let noteHex = "bab7b02640fe6a791c8bdb7a352995522842ccb55779b21bab42cc1049450ca5"
        let tags: [[String]] = [["p", profileHex]]
        let (attributedContent, _) = sut.parse(
            content: content,
            tags: tags,
            context: testContext
        )
        let links = attributedContent.links
        XCTAssertEqual(links.count, 2)
        XCTAssertEqual(links[safe: 0]?.key, "🔗 Link to note")
        XCTAssertEqual(links[safe: 0]?.value, URL(string: "%\(noteHex)"))
        XCTAssertEqual(links[safe: 1]?.key, "\(profileDisplayName)")
        XCTAssertEqual(links[safe: 1]?.value, URL(string: "@\(profileHex)"))
    }

    @MainActor func testNIP27MentionPrecededByAt() throws {
        // Arrange
        let name = "nos"
        let npub = "npub1pu3vqm4vzqpxsnhuc684dp2qaq6z69sf65yte4p39spcucv5lzmqswtfch"
        let hex = "0f22c06eac1002684efcc68f568540e8342d1609d508bcd4312c038e6194f8b6"

        // The @ symbol before nostr: should not break the parsing
        let content = "Ping @nostr:\(npub)"
        let expected = "Ping @\(name)"

        let tags = [
            ["p", hex],
            ["p", "8c430bdaadc1a202e4dd11c86c82546bb108d755e374b7918181f533b94e312e"],
            ["e", "a9788ca56a90bb5b856e89f16f5f3b0da93c28ea625e845c9925a41377152a13", "", "root"],
            ["e", "3d9503a2d4ad024749b138c041e99934474e2822e2a1c697792dab5b24acc285", "", "reply"]
        ]

        // Act
        let author = try Author.findOrCreate(by: hex, context: testContext)
        author.displayName = name
        try testContext.save()

        let (attributedContent, _) = sut.parse(
            content: content,
            tags: tags,
            context: testContext
        )

        // Assert
        let parsedContent = String(attributedContent.characters)
        XCTAssertEqual(parsedContent, expected)
        let links = attributedContent.links
        XCTAssertEqual(links.count, 1)
        XCTAssertEqual(links.first?.key, "@\(name)")
        XCTAssertEqual(links.first?.value, URL(string: "@\(hex)"))
    }

    @MainActor func testNIP27MentionToProfileWithURLInName() throws {
        // Arrange
        let name = "nos.social" // This should not break the parsing
        let npub = "npub1pu3vqm4vzqpxsnhuc684dp2qaq6z69sf65yte4p39spcucv5lzmqswtfch"
        let hex = "0f22c06eac1002684efcc68f568540e8342d1609d508bcd4312c038e6194f8b6"

        let content = "Yep. Something like that. I, of course could implement it " +
            "in nostr:\(npub) but haven’t yet."
        let expected = "Yep. Something like that. I, of course could implement it " +
            "in @\(name) but haven’t yet."

        let tags = [
            ["p", hex],
            ["p", "8c430bdaadc1a202e4dd11c86c82546bb108d755e374b7918181f533b94e312e"],
            ["e", "a9788ca56a90bb5b856e89f16f5f3b0da93c28ea625e845c9925a41377152a13", "", "root"],
            ["e", "3d9503a2d4ad024749b138c041e99934474e2822e2a1c697792dab5b24acc285", "", "reply"]
        ]

        // Act
        let author = try Author.findOrCreate(by: hex, context: testContext)
        author.displayName = name
        try testContext.save()
        let (attributedContent, _) = sut.parse(
            content: content,
            tags: tags,
            context: testContext
        )

        // Assert
        let parsedContent = String(attributedContent.characters)
        XCTAssertEqual(parsedContent, expected)
        let links = attributedContent.links
        XCTAssertEqual(links.count, 1)
        XCTAssertEqual(links.first?.key, "@\(name)")
        XCTAssertEqual(links.first?.value, URL(string: "@\(hex)"))
    }
}
