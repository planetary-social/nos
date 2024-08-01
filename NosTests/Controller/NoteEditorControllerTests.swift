import XCTest
import UIKit

// swiftlint:disable implicitly_unwrapped_optional
final class NoteEditorControllerTests: XCTestCase {
    
    var subject: NoteEditorController!
    var textView: UITextView!

    override func setUpWithError() throws {
        subject = NoteEditorController()
        textView = UITextView()
        subject.textView = textView
    }
    
    func testShowMentionsSearch_whenTypingAfterSpace_thenMentionsSearchIsShown() throws {
        // Arrange
        subject.append(text: " ")
        textView.selectedRange = NSRange(location: 1, length: 0)
        
        // Act
        let shouldChange = subject.textView(textView, shouldChangeTextIn: textView.selectedRange, replacementText: "@")
        
        // Assert
        XCTAssertEqual(subject.showMentionsSearch, true)
        XCTAssertEqual(shouldChange, true)
    }

    func testShowMentionsSearch_whenTypingInMiddleOfWord_thenMentionsSearchIsNotShown() throws {
        // Arrange
        subject.append(text: "blah")
        textView.selectedRange = NSRange(location: 4, length: 0)
        
        // Act
        let shouldChange = subject.textView(textView, shouldChangeTextIn: textView.selectedRange, replacementText: "@")
        
        // Assert
        XCTAssertEqual(subject.showMentionsSearch, false)
        XCTAssertEqual(shouldChange, true)
    }
    
    func testShowMentionsSearch_whenTypingInEmptyField_thenMentionsSearchIsShown() throws {
        // Arrange
        textView.selectedRange = NSRange(location: 0, length: 0)
        
        // Act
        let shouldChange = subject.textView(textView, shouldChangeTextIn: textView.selectedRange, replacementText: "@")
        
        // Assert
        XCTAssertEqual(subject.showMentionsSearch, true)
        XCTAssertEqual(shouldChange, true)
    }
    
    func testShowMentionsSearch_whenTypingAtStartOfLine_thenMentionsSearchIsShown() throws {
        // Arrange
        subject.append(text: "\n")
        textView.selectedRange = NSRange(location: 1, length: 0)
        
        // Act
        let shouldChange = subject.textView(textView, shouldChangeTextIn: textView.selectedRange, replacementText: "@")
        
        // Assert
        XCTAssertEqual(subject.showMentionsSearch, true)
        XCTAssertEqual(shouldChange, true)
    }
    //    @MainActor func testMention() throws {
    //        // Arrange
    //        let name = "mattn"
    //        let npub = "npub1937vv2nf06360qn9y8el6d8sevnndy7tuh5nzre4gj05xc32tnwqauhaj6"
    //        let hex = "2c7cc62a697ea3a7826521f3fd34f0cb273693cbe5e9310f35449f43622a5cdc"
    //        let author = try Author.findOrCreate(by: hex, context: testContext)
    //        author.displayName = name
    //        try testContext.save()
    //
    //        var editableNoteText = EditableNoteText(
    //            nsAttributedString: NSAttributedString(string: "@"),
    //            font: .systemFont(ofSize: 17),
    //            foregroundColor: .black
    //        )
    //        editableNoteText.insertMention(
    //            of: author,
    //            at: editableNoteText.attributedString.endIndex
    //        )
    //
    //        // UITextViews use a NSTextStorage instance that can update the actual
    //        // NSAttributedString we set. So, lets better use it here so we mimic
    //        // the same behavior.
    //        let textStorage = NSTextStorage()
    //        textStorage.setAttributedString(editableNoteText.nsAttributedString)
    //        let result = textStorage.attributedSubstring(
    //            from: NSRange(
    //                location: 0,
    //                length: editableNoteText.nsAttributedString.length
    //            )
    //        )
    //
    //        // Act
    //        let expected = "nostr:\(npub) "
    //        let (content, _) = sut.parse(
    //            attributedText: AttributedString(result)
    //        )
    //
    //        // Assert
    //        XCTAssertEqual(content, expected)
    //    }
    //
    //    @MainActor func testMentionWithEmoji() throws {
    //        // Arrange
    //        let name = "mattn 🍐"
    //        let npub = "npub1937vv2nf06360qn9y8el6d8sevnndy7tuh5nzre4gj05xc32tnwqauhaj6"
    //        let hex = "2c7cc62a697ea3a7826521f3fd34f0cb273693cbe5e9310f35449f43622a5cdc"
    //        let author = try Author.findOrCreate(by: hex, context: testContext)
    //        author.displayName = name
    //        try testContext.save()
    //
    //        var editableNoteText = EditableNoteText(
    //            nsAttributedString: NSAttributedString(string: "@"),
    //            font: .systemFont(ofSize: 17),
    //            foregroundColor: .black
    //        )
    //        editableNoteText.insertMention(
    //            of: author,
    //            at: editableNoteText.attributedString.endIndex
    //        )
    //
    //        // UITextViews use a NSTextStorage instance that can update the actual
    //        // NSAttributedString we set. So, lets better use it here so we mimic
    //        // the same behavior.
    //        // In the case of emojis, it modifies the font.
    //        let textStorage = NSTextStorage()
    //        textStorage.setAttributedString(editableNoteText.nsAttributedString)
    //        let result = textStorage.attributedSubstring(
    //            from: NSRange(
    //                location: 0,
    //                length: editableNoteText.nsAttributedString.length
    //            )
    //        )
    //
    //        // Act
    //        let expected = "nostr:\(npub) "
    //        let (content, _) = sut.parse(
    //            attributedText: AttributedString(result)
    //        )
    //
    //        // Assert
    //        XCTAssertEqual(content, expected)
    //    }
    //
    //    @MainActor func testMentionWithEmojiBeforeAndAfter() throws {
    //        // Arrange
    //        let name = "🍐 mattn 🍐"
    //        let npub = "npub1937vv2nf06360qn9y8el6d8sevnndy7tuh5nzre4gj05xc32tnwqauhaj6"
    //        let hex = "2c7cc62a697ea3a7826521f3fd34f0cb273693cbe5e9310f35449f43622a5cdc"
    //        let author = try Author.findOrCreate(by: hex, context: testContext)
    //        author.displayName = name
    //        try testContext.save()
    //
    //        var editableNoteText = EditableNoteText(
    //            nsAttributedString: NSAttributedString(string: "@"),
    //            font: .systemFont(ofSize: 17),
    //            foregroundColor: .black
    //        )
    //        editableNoteText.insertMention(
    //            of: author,
    //            at: editableNoteText.attributedString.endIndex
    //        )
    //
    //        // UITextViews use a NSTextStorage instance that can update the actual
    //        // NSAttributedString we set. So, lets better use it here so we mimic
    //        // the same behavior.
    //        // In the case of emojis, it modifies the font.
    //        let textStorage = NSTextStorage()
    //        textStorage.setAttributedString(editableNoteText.nsAttributedString)
    //        let result = textStorage.attributedSubstring(
    //            from: NSRange(
    //                location: 0,
    //                length: editableNoteText.nsAttributedString.length
    //            )
    //        )
    //
    //        // Act
    //        let expected = "nostr:\(npub) "
    //        let (content, _) = sut.parse(
    //            attributedText: AttributedString(result)
    //        )
    //
    //        // Assert
    //        XCTAssertEqual(content, expected)
    //    }
    //
    //    @MainActor func testTwoMentionsWithEmojiBeforeAndAfter() throws {
    //        // Arrange
    //        let name = "🍐 mattn 🍐"
    //        let npub = "npub1937vv2nf06360qn9y8el6d8sevnndy7tuh5nzre4gj05xc32tnwqauhaj6"
    //        let hex = "2c7cc62a697ea3a7826521f3fd34f0cb273693cbe5e9310f35449f43622a5cdc"
    //        let author = try Author.findOrCreate(by: hex, context: testContext)
    //        author.displayName = name
    //        try testContext.save()
    //
    //        var editableNoteText = EditableNoteText(
    //            nsAttributedString: NSAttributedString(string: "@"),
    //            font: .systemFont(ofSize: 17),
    //            foregroundColor: .black
    //        )
    //        editableNoteText.insertMention(
    //            of: author,
    //            at: editableNoteText.attributedString.endIndex
    //        )
    //        editableNoteText.append("two mentions @")
    //        editableNoteText.insertMention(
    //            of: author,
    //            at: editableNoteText.attributedString.endIndex
    //        )
    //
    //        // UITextViews use a NSTextStorage instance that can update the actual
    //        // NSAttributedString we set. So, lets better use it here so we mimic
    //        // the same behavior.
    //        // In the case of emojis, it modifies the font.
    //        let textStorage = NSTextStorage()
    //        textStorage.setAttributedString(editableNoteText.nsAttributedString)
    //        let result = textStorage.attributedSubstring(
    //            from: NSRange(
    //                location: 0,
    //                length: editableNoteText.nsAttributedString.length
    //            )
    //        )
    //
    //        // Act
    //        let expected = "nostr:\(npub) two mentions nostr:\(npub) "
    //        let (content, _) = sut.parse(
    //            attributedText: AttributedString(result)
    //        )
    //
    //        // Assert
    //        XCTAssertEqual(content, expected)
    //    }
}

// swiftlint:enable implicitly_unwrapped_optional
