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

        var editableNoteText = EditableNoteText(
            nsAttributedString: NSAttributedString(string: "@"),
            font: .systemFont(ofSize: 17),
            foregroundColor: .black
        )
        editableNoteText.insertMention(
            of: author,
            at: editableNoteText.attributedString.endIndex
        )

        // UITextViews use a NSTextStorage instance that can update the actual
        // NSAttributedString we set. So, lets better use it here so we mimic
        // the same behavior.
        let textStorage = NSTextStorage()
        textStorage.setAttributedString(editableNoteText.nsAttributedString)
        let result = textStorage.attributedSubstring(
            from: NSRange(
                location: 0,
                length: editableNoteText.nsAttributedString.length
            )
        )

        // Act
        let expected = "nostr:\(npub) "
        let (content, _) = sut.parse(
            attributedText: AttributedString(result)
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

        var editableNoteText = EditableNoteText(
            nsAttributedString: NSAttributedString(string: "@"),
            font: .systemFont(ofSize: 17),
            foregroundColor: .black
        )
        editableNoteText.insertMention(
            of: author,
            at: editableNoteText.attributedString.endIndex
        )

        // UITextViews use a NSTextStorage instance that can update the actual
        // NSAttributedString we set. So, lets better use it here so we mimic
        // the same behavior.
        // In the case of emojis, it modifies the font.
        let textStorage = NSTextStorage()
        textStorage.setAttributedString(editableNoteText.nsAttributedString)
        let result = textStorage.attributedSubstring(
            from: NSRange(
                location: 0,
                length: editableNoteText.nsAttributedString.length
            )
        )

        // Act
        let expected = "nostr:\(npub) "
        let (content, _) = sut.parse(
            attributedText: AttributedString(result)
        )

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

        var editableNoteText = EditableNoteText(
            nsAttributedString: NSAttributedString(string: "@"),
            font: .systemFont(ofSize: 17),
            foregroundColor: .black
        )
        editableNoteText.insertMention(
            of: author,
            at: editableNoteText.attributedString.endIndex
        )

        // UITextViews use a NSTextStorage instance that can update the actual
        // NSAttributedString we set. So, lets better use it here so we mimic
        // the same behavior.
        // In the case of emojis, it modifies the font.
        let textStorage = NSTextStorage()
        textStorage.setAttributedString(editableNoteText.nsAttributedString)
        let result = textStorage.attributedSubstring(
            from: NSRange(
                location: 0,
                length: editableNoteText.nsAttributedString.length
            )
        )

        // Act
        let expected = "nostr:\(npub) "
        let (content, _) = sut.parse(
            attributedText: AttributedString(result)
        )

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

        var editableNoteText = EditableNoteText(
            nsAttributedString: NSAttributedString(string: "@"),
            font: .systemFont(ofSize: 17),
            foregroundColor: .black
        )
        editableNoteText.insertMention(
            of: author,
            at: editableNoteText.attributedString.endIndex
        )
        editableNoteText.append("two mentions @")
        editableNoteText.insertMention(
            of: author,
            at: editableNoteText.attributedString.endIndex
        )

        // UITextViews use a NSTextStorage instance that can update the actual
        // NSAttributedString we set. So, lets better use it here so we mimic
        // the same behavior.
        // In the case of emojis, it modifies the font.
        let textStorage = NSTextStorage()
        textStorage.setAttributedString(editableNoteText.nsAttributedString)
        let result = textStorage.attributedSubstring(
            from: NSRange(
                location: 0,
                length: editableNoteText.nsAttributedString.length
            )
        )

        // Act
        let expected = "nostr:\(npub) two mentions nostr:\(npub) "
        let (content, _) = sut.parse(
            attributedText: AttributedString(result)
        )

        // Assert
        XCTAssertEqual(content, expected)
    }
}
