import Foundation
import UIKit
import XCTest

/// Collection of tests that exercise NoteParser.parse() function. This function
/// is the one Nos uses for converting editor generated text to note content
/// when publishing.
extension NoteParserTests {

    @MainActor func testMention() throws {
        // Arrange
        let name = "mattn"
        let npub = "npub1937vv2nf06360qn9y8el6d8sevnndy7tuh5nzre4gj05xc32tnwqauhaj6"
        let hex = "2c7cc62a697ea3a7826521f3fd34f0cb273693cbe5e9310f35449f43622a5cdc"
        let author = try Author.findOrCreate(by: hex, context: testContext)
        author.displayName = name
        try testContext.save()

        noteEditor.append(text: "@")
        noteEditor.insertMention(of: author)

        // Act
        let expected = "nostr:\(npub) "
        let (content, _) = sut.parse(
            attributedText: noteEditor.text!
        )

        // Assert
        XCTAssertEqual(content, expected)
    }

    @MainActor func testMentionWithEmoji() throws {
        // Arrange
        let name = "mattn 🍐"
        let npub = "npub1937vv2nf06360qn9y8el6d8sevnndy7tuh5nzre4gj05xc32tnwqauhaj6"
        let hex = "2c7cc62a697ea3a7826521f3fd34f0cb273693cbe5e9310f35449f43622a5cdc"
        let author = try Author.findOrCreate(by: hex, context: testContext)
        author.displayName = name
        try testContext.save()

        noteEditor.append(text: "@")
        noteEditor.insertMention(of: author)

        // Act
        let expected = "nostr:\(npub) "
        let (content, _) = sut.parse(attributedText: noteEditor.text!)

        // Assert
        XCTAssertEqual(content, expected)
    }

    @MainActor func testMentionWithEmojiBeforeAndAfter() throws {
        // Arrange
        let name = "🍐 mattn 🍐"
        let npub = "npub1937vv2nf06360qn9y8el6d8sevnndy7tuh5nzre4gj05xc32tnwqauhaj6"
        let hex = "2c7cc62a697ea3a7826521f3fd34f0cb273693cbe5e9310f35449f43622a5cdc"
        let author = try Author.findOrCreate(by: hex, context: testContext)
        author.displayName = name
        try testContext.save()

        noteEditor.append(text: "@")
        noteEditor.insertMention(of: author)

        // Act
        let expected = "nostr:\(npub) "
        let (content, _) = sut.parse(attributedText: noteEditor.text!)

        // Assert
        XCTAssertEqual(content, expected)
    }

    /// Example taken from [NIP-27](https://github.com/nostr-protocol/nips/blob/master/27.md)
    func testMentionWithNpub() throws {
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

    @MainActor func testTwoMentionsWithEmojiBeforeAndAfter() throws {
        // Arrange
        let name = "🍐 mattn 🍐"
        let npub = "npub1937vv2nf06360qn9y8el6d8sevnndy7tuh5nzre4gj05xc32tnwqauhaj6"
        let hex = "2c7cc62a697ea3a7826521f3fd34f0cb273693cbe5e9310f35449f43622a5cdc"
        let author = try Author.findOrCreate(by: hex, context: testContext)
        author.displayName = name
        try testContext.save()

        noteEditor.append(text: "@")
        noteEditor.insertMention(of: author)
        noteEditor.append(text: "two mentions @")
        noteEditor.insertMention(of: author)
        textView.selectedRange = NSRange(location: textView.text.count, length: 0)
        
        // Act
        let expected = "nostr:\(npub) two mentions nostr:\(npub) "
        let (content, _) = sut.parse(attributedText: noteEditor.text!)

        // Assert
        XCTAssertEqual(content, expected)
    }

    @MainActor func test_parse_returns_hashtag() throws {
        // Arrange
        let text = "#photography"

        // Act
        let expected = [["t", "photography"]]
        let result = sut.hashtags(in: text)

        // Assert
        XCTAssertEqual(result, expected)
    }

    @MainActor func test_parse_returns_hashtag_lowercased() throws {
        // Arrange
        let text = "#DOGS"

        // Act
        let expected = [["t", "dogs"]]
        let result = sut.hashtags(in: text)

        // Assert
        XCTAssertEqual(result, expected)
    }

    @MainActor func test_parse_returns_hashtag_without_punctuation() throws {
        // Arrange
        let text = "check out my #hashtag! #hello, #world."

        // Act
        let expected = [["t", "hashtag"], ["t", "hello"], ["t", "world"]]
        let result = sut.hashtags(in: text)

        // Assert
        XCTAssertEqual(result, expected)
    }

    @MainActor func test_parse_returns_multiple_hashtags() throws {
        // Arrange
        let text = "#photography #birds #canada"

        // Act
        let expected = [["t", "photography"], ["t", "birds"], ["t", "canada"]]
        let result = sut.hashtags(in: text)

        // Assert
        XCTAssertEqual(result, expected)
    }

    @MainActor func test_parse_returns_no_hashtags() throws {
        // Arrange
        let text = "example.com#photography"

        // Act
        let expected: [[String]] = []
        let result = sut.hashtags(in: text)

        // Assert
        XCTAssertEqual(result, expected)
    }

    func test_parse_mention_and_hashtag() throws {
        let mention = "@mattn"
        let npub = "npub1937vv2nf06360qn9y8el6d8sevnndy7tuh5nzre4gj05xc32tnwqauhaj6"
        let hex = "2c7cc62a697ea3a7826521f3fd34f0cb273693cbe5e9310f35449f43622a5cdc"
        let link = "nostr:\(npub)"
        let markdown = "hello [\(mention)](\(link)) #greetings #hi"
        let attributedString = try AttributedString(markdown: markdown)
        let (content, tags) = sut.parse(
            attributedText: attributedString
        )
        let expectedContent = "hello nostr:\(npub) #greetings #hi"
        let expectedTags = [["p", hex], ["t", "greetings"], ["t", "hi"]]
        XCTAssertEqual(content, expectedContent)
        XCTAssertEqual(tags, expectedTags)
    }
}
