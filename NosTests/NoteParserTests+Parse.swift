//
//  NoteParserTests+Parse.swift
//  NosTests
//
//  Created by Martin Dutra on 11/6/24.
//

import Foundation
import UIKit
import XCTest

extension NoteParserTests {

    func testMention() throws {
        // Arrange
        let name = "mattn"
        let npub = "npub1937vv2nf06360qn9y8el6d8sevnndy7tuh5nzre4gj05xc32tnwqauhaj6"
        let hex = "2c7cc62a697ea3a7826521f3fd34f0cb273693cbe5e9310f35449f43622a5cdc"
        let context = try XCTUnwrap(testContext)
        let author = try Author.findOrCreate(by: hex, context: context)
        author.displayName = name
        try context.save()

        var editableNoteText = EditableNoteText(
            nsAttributedString: NSAttributedString(string: "@"),
            font: .systemFont(ofSize: 17),
            foregroundColor: .black
        )
        editableNoteText.insertMention(
            of: author,
            at: editableNoteText.attributedString.endIndex
        )

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
        let (content, tags) = sut.parse(
            attributedText: AttributedString(result)
        )

        // Assert
        XCTAssertEqual(content, expected)
    }

    func testMentionWithEmoji() throws {
        // Arrange
        let name = "mattn 🍐"
        let npub = "npub1937vv2nf06360qn9y8el6d8sevnndy7tuh5nzre4gj05xc32tnwqauhaj6"
        let hex = "2c7cc62a697ea3a7826521f3fd34f0cb273693cbe5e9310f35449f43622a5cdc"
        let context = try XCTUnwrap(testContext)
        let author = try Author.findOrCreate(by: hex, context: context)
        author.displayName = name
        try context.save()

        var editableNoteText = EditableNoteText(
            nsAttributedString: NSAttributedString(string: "@"),
            font: .systemFont(ofSize: 17),
            foregroundColor: .black
        )
        editableNoteText.insertMention(
            of: author,
            at: editableNoteText.attributedString.endIndex
        )

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
        let (content, tags) = sut.parse(
            attributedText: AttributedString(result)
        )

        // Assert
        XCTAssertEqual(content, expected)
    }

}
