import Foundation
import UIKit
import XCTest

/// Collection of tests that exercise NoteParser.parse() function. This fubction
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
}
