import XCTest
import UIKit

// swiftlint:disable implicitly_unwrapped_optional
final class NoteEditorControllerTests: CoreDataTestCase {
    
    var subject: NoteEditorController!
    var textView: UITextView!

    override func setUpWithError() throws {
        subject = NoteEditorController()
        textView = UITextView()
        subject.textView = textView
    }
    
    // MARK: - Show Mentions Search
    
    func testShowMentionsAutocomplete_whenTypingAfterSpace_thenMentionsSearchIsShown() throws {
        // Arrange
        subject.append(text: " ")
        textView.selectedRange = NSRange(location: 1, length: 0)
        
        // Act
        let shouldChange = subject.textView(textView, shouldChangeTextIn: textView.selectedRange, replacementText: "@")
        
        // Assert
        XCTAssertEqual(subject.showMentionsAutocomplete, true)
        XCTAssertEqual(shouldChange, true)
    }

    func testShowMentionsAutocomplete_whenTypingInMiddleOfWord_thenMentionsSearchIsNotShown() throws {
        // Arrange
        subject.append(text: "blah")
        textView.selectedRange = NSRange(location: 4, length: 0)
        
        // Act
        let shouldChange = subject.textView(textView, shouldChangeTextIn: textView.selectedRange, replacementText: "@")
        
        // Assert
        XCTAssertEqual(subject.showMentionsAutocomplete, false)
        XCTAssertEqual(shouldChange, true)
    }
    
    func testShowMentionsAutocomplete_whenTypingInEmptyField_thenMentionsSearchIsShown() throws {
        // Arrange
        textView.selectedRange = NSRange(location: 0, length: 0)
        
        // Act
        let shouldChange = subject.textView(textView, shouldChangeTextIn: textView.selectedRange, replacementText: "@")
        
        // Assert
        XCTAssertEqual(subject.showMentionsAutocomplete, true)
        XCTAssertEqual(shouldChange, true)
    }
    
    func testShowMentionsAutocomplete_whenTypingAtStartOfLine_thenMentionsSearchIsShown() throws {
        // Arrange
        subject.append(text: "\n")
        textView.selectedRange = NSRange(location: 1, length: 0)
        
        // Act
        let shouldChange = subject.textView(textView, shouldChangeTextIn: textView.selectedRange, replacementText: "@")
        
        // Assert
        XCTAssertEqual(subject.showMentionsAutocomplete, true)
        XCTAssertEqual(shouldChange, true)
    }
    
    // MARK: - mentions 
    
    @MainActor func testMention() throws {
        // Arrange
        let name = "mattn"
        let npub = "npub1937vv2nf06360qn9y8el6d8sevnndy7tuh5nzre4gj05xc32tnwqauhaj6"
        let hex = "2c7cc62a697ea3a7826521f3fd34f0cb273693cbe5e9310f35449f43622a5cdc"
        let author = try Author.findOrCreate(by: hex, context: testContext)
        author.displayName = name
        try testContext.save()
        subject.append(text: "@")
        
        // Act
        subject.insertMention(of: author)
        
        // Assert
        let expectedText = AttributedString(NSAttributedString(string: "@mattn", attributes: [
            .font: UIFont.preferredFont(forTextStyle: .body),
            .foregroundColor: UIColor.primaryTxt,
            .link: "nostr:\(npub)"
        ]))
        XCTAssertEqual(subject.text, expectedText)
    }

    @MainActor func testMentionWithEmoji() throws {
        // Arrange
        let name = "mattn 🍐"
        let npub = "npub1937vv2nf06360qn9y8el6d8sevnndy7tuh5nzre4gj05xc32tnwqauhaj6"
        let hex = "2c7cc62a697ea3a7826521f3fd34f0cb273693cbe5e9310f35449f43622a5cdc"
        let author = try Author.findOrCreate(by: hex, context: testContext)
        author.displayName = name
        try testContext.save()
        subject.append(text: "@")

        // Act
        subject.insertMention(of: author)
        
        // Assert
        let expectedText = AttributedString(NSAttributedString(string: "@mattn 🍐", attributes: [
            .font: UIFont.preferredFont(forTextStyle: .body),
            .foregroundColor: UIColor.primaryTxt,
            .link: "nostr:\(npub)"
        ]))
        XCTAssertEqual(subject.text, expectedText)
    }

    @MainActor func testMentionWithEmojiBeforeAndAfter() throws {
        // Arrange
        let name = "🍐 mattn 🍐"
        let npub = "npub1937vv2nf06360qn9y8el6d8sevnndy7tuh5nzre4gj05xc32tnwqauhaj6"
        let hex = "2c7cc62a697ea3a7826521f3fd34f0cb273693cbe5e9310f35449f43622a5cdc"
        let author = try Author.findOrCreate(by: hex, context: testContext)
        author.displayName = name
        try testContext.save()
        subject.append(text: "@")
        
        // Act
        subject.insertMention(of: author)
        
        // Assert
        let expectedText = AttributedString(NSAttributedString(string: "@🍐 mattn 🍐", attributes: [
            .font: UIFont.preferredFont(forTextStyle: .body),
            .foregroundColor: UIColor.primaryTxt,
            .link: "nostr:\(npub)"
        ]))
        XCTAssertEqual(subject.text, expectedText)
    }

    @MainActor func testTwoMentionsWithEmojiBeforeAndAfter() throws {
        // Arrange
        let name = "🍐 mattn 🍐"
        let npub = "npub1937vv2nf06360qn9y8el6d8sevnndy7tuh5nzre4gj05xc32tnwqauhaj6"
        let hex = "2c7cc62a697ea3a7826521f3fd34f0cb273693cbe5e9310f35449f43622a5cdc"
        let author = try Author.findOrCreate(by: hex, context: testContext)
        author.displayName = name
        try testContext.save()
        subject.append(text: "@")
        
        // Act
        subject.insertMention(of: author)
        subject.append(text: " @")
        subject.insertMention(of: author)
        
        // Assert
        let mention = NSAttributedString(string: "@🍐 mattn 🍐", attributes: [
            .font: UIFont.preferredFont(forTextStyle: .body),
            .foregroundColor: UIColor.primaryTxt,
            .link: "nostr:\(npub)"
        ])
        
        let expectedText = NSMutableAttributedString(attributedString: mention)
        expectedText.append(NSAttributedString(string: " ", attributes: [
            .font: UIFont.preferredFont(forTextStyle: .body),
            .foregroundColor: UIColor.primaryTxt
        ]))
        expectedText.append(mention)
        XCTAssertEqual(subject.text, AttributedString(expectedText))
    }
    
    @MainActor func testRemoveLinkAttributesUnderCursor_whenDeletingLastCharacterOfMention() throws {
        // Arrange
        let name = "abc"
        let npub = "npub1937vv2nf06360qn9y8el6d8sevnndy7tuh5nzre4gj05xc32tnwqauhaj6"
        let hex = "2c7cc62a697ea3a7826521f3fd34f0cb273693cbe5e9310f35449f43622a5cdc"
        let author = try Author.findOrCreate(by: hex, context: testContext)
        author.displayName = name
        try testContext.save()
        subject.append(text: "@")
        
        // Act
        subject.insertMention(of: author)
        // simulate a backspace
        _ = subject.textView(textView, shouldChangeTextIn: NSRange(location: 3, length: 1), replacementText: "")
        
        // Assert
        let expectedText = NSAttributedString(string: "@ab", attributes: [
            .font: UIFont.preferredFont(forTextStyle: .body),
            .foregroundColor: UIColor.primaryTxt,
        ])
        
        XCTAssertEqual(subject.text, AttributedString(expectedText))
    }
    
    @MainActor func testRemoveLinkAttributesUnderCursor_whenDeletingACharacterAfterAMention() throws {
        // Arrange
        let name = "abc"
        let npub = "npub1937vv2nf06360qn9y8el6d8sevnndy7tuh5nzre4gj05xc32tnwqauhaj6"
        let hex = "2c7cc62a697ea3a7826521f3fd34f0cb273693cbe5e9310f35449f43622a5cdc"
        let author = try Author.findOrCreate(by: hex, context: testContext)
        author.displayName = name
        try testContext.save()
        subject.append(text: "@")
        
        // Act
        subject.insertMention(of: author)
        subject.append(text: ".")
        // simulate a backspace
        let shouldChange = subject.textView(
            textView, 
            shouldChangeTextIn: NSRange(location: 4, length: 1), 
            replacementText: ""
        )
        
        // Assert
        // The backspace should be handled by the UITextView, not our code.
        XCTAssertEqual(shouldChange, true)
    }
}

// swiftlint:enable implicitly_unwrapped_optional
