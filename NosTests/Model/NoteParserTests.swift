import CoreData
import XCTest
import Dependencies

final class NoteParserTests: CoreDataTestCase {

    // swiftlint:disable:next implicitly_unwrapped_optional
    var sut: NoteParser!

    override func setUp() async throws {
        sut = NoteParser()
        try await super.setUp()
    }

    func testContentWithRawNpubPrecededByAt() throws {
        // Arrange
        let npub = "npub1pu3vqm4vzqpxsnhuc684dp2qaq6z69sf65yte4p39spcucv5lzmqswtfch"
        let hex = "0f22c06eac1002684efcc68f568540e8342d1609d508bcd4312c038e6194f8b6"
        let content = "You can find me at @\(npub)"
        let expected = "You can find me at \(npub)"

        // Act
        let tags: [[String]] = [[]]
        let context = try XCTUnwrap(testContext)
        let (attributedContent, _) = sut.parse(
            content: content,
            tags: tags,
            context: context
        )

        // Assert
        XCTAssertEqual(String(attributedContent.characters), expected)
        let links = attributedContent.links
        XCTAssertEqual(links.count, 1)
        XCTAssertEqual(links[safe: 0]?.key, npub)
        XCTAssertEqual(links[safe: 0]?.value, URL(string: "@\(hex)"))
    }

    func testContentWithRawNIP05() throws {
        // Arrange
        let nip05 = "linda@nos.social"
        let webLink = "https://njump.me/\(nip05)"
        let content = "hello \(nip05)"
        let expected = content

        // Act
        let tags: [[String]] = [[]]
        let context = try XCTUnwrap(testContext)
        let (attributedContent, _) = sut.parse(
            content: content,
            tags: tags,
            context: context
        )

        // Assert
        XCTAssertEqual(String(attributedContent.characters), expected)
        let links = attributedContent.links
        XCTAssertEqual(links.count, 1)
        XCTAssertEqual(links[safe: 0]?.key, nip05)
        XCTAssertEqual(links[safe: 0]?.value, URL(string: webLink))
    }

    func testContentWithRawNIP05AndAtPrepended() throws {
        // Arrange
        let nip05 = "linda@nos.social"
        let webLink = "https://njump.me/\(nip05)"
        let content = "hello @\(nip05)"
        let expected = "hello \(nip05)"

        // Act
        let tags: [[String]] = [[]]
        let context = try XCTUnwrap(testContext)
        let (attributedContent, _) = sut.parse(
            content: content,
            tags: tags,
            context: context
        )

        // Assert
        XCTAssertEqual(String(attributedContent.characters), expected)
        let links = attributedContent.links
        XCTAssertEqual(links.count, 1)
        XCTAssertEqual(links[safe: 0]?.key, nip05)
        XCTAssertEqual(links[safe: 0]?.value, URL(string: webLink))
    }
    
    /// Example taken from [NIP-27](https://github.com/nostr-protocol/nips/blob/master/27.md)
    func testMentionWithNPub() throws {
        let mention = "@mattn"
        let npub = "npub1937vv2nf06360qn9y8el6d8sevnndy7tuh5nzre4gj05xc32tnwqauhaj6"
        let hex = "2c7cc62a697ea3a7826521f3fd34f0cb273693cbe5e9310f35449f43622a5cdc"
        let link = "nostr:\(npub)"
        let markdown = "hello [\(mention)](\(link))"
        let attributedString = try AttributedString(markdown: markdown)
        let (content, tags) = sut.parse(
            attributedText: attributedString
        )
        let expectedContent = "hello nostr:\(npub)"
        let expectedTags = [["p", hex]]
        XCTAssertEqual(content, expectedContent)
        XCTAssertEqual(tags, expectedTags)
    }
    
    func testContentWithMixedMentions() throws {
        let content = "hello nostr:npub1937vv2nf06360qn9y8el6d8sevnndy7tuh5nzre4gj05xc32tnwqauhaj6 and #[1]"
        let displayName1 = "npub1937vv..."
        let hex1 = "2c7cc62a697ea3a7826521f3fd34f0cb273693cbe5e9310f35449f43622a5cdc"
        let displayName2 = "npub180cvv..."
        let hex2 = "3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459d"
        let tags = [["p", hex1], ["p", hex2]]
        let context = try XCTUnwrap(testContext)
        let (attributedContent, _) = sut.parse(
            content: content,
            tags: tags,
            context: context
        )
        let links = attributedContent.links
        XCTAssertEqual(links.count, 2)
        XCTAssertEqual(links[safe: 0]?.key, "@\(displayName1)")
        XCTAssertEqual(links[safe: 0]?.value, URL(string: "@\(hex1)"))
        XCTAssertEqual(links[safe: 1]?.key, "@\(displayName2)")
        XCTAssertEqual(links[safe: 1]?.value, URL(string: "@\(hex2)"))
    }

    func testContentWithUntaggedNpub() throws {
        let content = "hello npub1937vv2nf06360qn9y8el6d8sevnndy7tuh5nzre4gj05xc32tnwqauhaj6"
        let npub = "npub1937vv2nf06360qn9y8el6d8sevnndy7tuh5nzre4gj05xc32tnwqauhaj6"
        let hex = "2c7cc62a697ea3a7826521f3fd34f0cb273693cbe5e9310f35449f43622a5cdc"
        let tags: [[String]] = [[]]
        let context = try XCTUnwrap(testContext)
        let (attributedContent, _) = sut.parse(
            content: content,
            tags: tags,
            context: context
        )
        let links = attributedContent.links
        XCTAssertEqual(links.count, 1)
        XCTAssertEqual(links[safe: 0]?.key, npub)
        XCTAssertEqual(links[safe: 0]?.value, URL(string: "@\(hex)"))
    }

    func testContentWithUntaggedNote() throws {
        let content = "Check this note1h2mmqfjqle48j8ytmdar22v42g5y9n942aumyxatgtxpqj29pjjsjecraw"
        let hex = "bab7b02640fe6a791c8bdb7a352995522842ccb55779b21bab42cc1049450ca5"
        let tags: [[String]] = [[]]
        let context = try XCTUnwrap(testContext)
        let (attributedContent, _) = sut.parse(
            content: content,
            tags: tags,
            context: context
        )
        let links = attributedContent.links
        XCTAssertEqual(links.count, 1)
        XCTAssertEqual(links[safe: 0]?.key, "🔗 Link to note")
        XCTAssertEqual(links[safe: 0]?.value, URL(string: "%\(hex)"))
    }
    
    func testContentWithUntaggedNIP27Note() throws {
        let content = "Check this nostr:note1h2mmqfjqle48j8ytmdar22v42g5y9n942aumyxatgtxpqj29pjjsjecraw"
        let hex = "bab7b02640fe6a791c8bdb7a352995522842ccb55779b21bab42cc1049450ca5"
        let tags: [[String]] = [[]]
        let context = try XCTUnwrap(testContext)
        let (attributedContent, _) = sut.parse(
            content: content,
            tags: tags,
            context: context
        )
        let links = attributedContent.links
        XCTAssertEqual(links.count, 1)
        XCTAssertEqual(links[safe: 0]?.key, "🔗 Link to note")
        XCTAssertEqual(links[safe: 0]?.value, URL(string: "%\(hex)"))
    }
    
    func testContentWithUntaggedProfile() throws {
        let profile = "nprofile1qqszclxx9f5haga8sfjjrulaxncvkfekj097t6f3pu65f86rvg49ehqj6f9dh"
        let hex = "2c7cc62a697ea3a7826521f3fd34f0cb273693cbe5e9310f35449f43622a5cdc"

        let content = "hello \(profile)"
        let tags: [[String]] = [[]]
        
        let expectedContent = content
        let context = try XCTUnwrap(testContext)
        let (attributedContent, _) = sut.parse(
            content: content,
            tags: tags,
            context: context
        )

        let parsedContent = String(attributedContent.characters)
        XCTAssertEqual(parsedContent, expectedContent)

        let links = attributedContent.links
        XCTAssertEqual(links.count, 1)
        XCTAssertEqual(links[safe: 0]?.key, "\(profile)")
        XCTAssertEqual(links[safe: 0]?.value, URL(string: "@\(hex)"))
    }

    func testContentWithUntaggedEvent() throws {
        // swiftlint:disable line_length
        let event = "nevent1qqst8cujky046negxgwwm5ynqwn53t8aqjr6afd8g59nfqwxpdhylpcpzamhxue69uhhyetvv9ujuetcv9khqmr99e3k7mg8arnc9"
        // swiftlint:enable line_length

        let hex = "b3e392b11f5d4f28321cedd09303a748acfd0487aea5a7450b3481c60b6e4f87"

        let content = "check this \(event)"
        let tags: [[String]] = [[]]

        let expectedContent = "check this 🔗 Link to note"
        let context = try XCTUnwrap(testContext)
        let (attributedContent, _) = sut.parse(
            content: content,
            tags: tags,
            context: context
        )

        let parsedContent = String(attributedContent.characters)
        XCTAssertEqual(parsedContent, expectedContent)

        let links = attributedContent.links
        XCTAssertEqual(links.count, 1)
        XCTAssertEqual(links[safe: 0]?.key, "🔗 Link to note")
        XCTAssertEqual(links[safe: 0]?.value, URL(string: "%\(hex)"))
    }

    func testContentWithUntaggedEventWithADot() throws {
        // swiftlint:disable line_length
        let event = "nevent1qqst8cujky046negxgwwm5ynqwn53t8aqjr6afd8g59nfqwxpdhylpcpzamhxue69uhhyetvv9ujuetcv9khqmr99e3k7mg8arnc9"
        // swiftlint:enable line_length

        let hex = "b3e392b11f5d4f28321cedd09303a748acfd0487aea5a7450b3481c60b6e4f87"

        let content = "check this \(event). Bye!"
        let tags: [[String]] = [[]]

        let expectedContent = "check this 🔗 Link to note. Bye!"
        let context = try XCTUnwrap(testContext)
        let (attributedContent, _) = sut.parse(
            content: content,
            tags: tags,
            context: context
        )

        let parsedContent = String(attributedContent.characters)
        XCTAssertEqual(parsedContent, expectedContent)

        let links = attributedContent.links
        XCTAssertEqual(links.count, 1)
        XCTAssertEqual(links[safe: 0]?.key, "🔗 Link to note")
        XCTAssertEqual(links[safe: 0]?.value, URL(string: "%\(hex)"))
    }

    func testContentWithMalformedEvent() throws {
        // swiftlint:disable line_length
        let event = "nevent1qqst8cujky046negxgwwm5ynqwn53t8aqjr6afd8g59nfqwxpdhylpcpzamhxue69uhhyetvv9ujuetcv9khqmr99e3k7mg8arnc9"
        // swiftlint:enable line_length

        let content = "check this \(event)andthisshouldbreakmaybe. Bye!"
        let tags: [[String]] = [[]]

        let expectedContent = content
        let context = try XCTUnwrap(testContext)
        let (attributedContent, _) = sut.parse(
            content: content,
            tags: tags,
            context: context
        )

        let parsedContent = String(attributedContent.characters)
        XCTAssertEqual(parsedContent, expectedContent)

        let links = attributedContent.links
        XCTAssertEqual(links.count, 0)
    }
}
