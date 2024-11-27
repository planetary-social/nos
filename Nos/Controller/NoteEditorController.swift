import Dependencies
import Foundation
import SwiftUI
import UIKit

/// A controller for Nostr note text that is being edited. This controller pairs with a `NoteUITextViewRepresentable`
/// to help our SwiftUI views interact with a UITextView cleanly.
/// 
/// To use: instantiate and pass into a `NoteTextEditor` view. You can retrieve the typed text via the `text` property
/// when the user indicates they are ready to post it.  
@Observable class NoteEditorController: NSObject, UITextViewDelegate {

    @ObservationIgnored @Dependency(\.analytics) private var analytics

    /// The height that fits all entered text. This value will be updated by `NoteUITextViewRepresentable` 
    /// automatically, and should be used to set the frame of `NoteUITextViewRepresentable` from SwiftUI. This is done 
    /// to work around some incompatibilities between UIKit and SwiftUI where the UITextView won't expand properly.
    var intrinsicHeight: CGFloat = 0
    
    /// A variable that controls whether the mention autocomplete window should be shown. This window is triggered
    /// by typing an '@' symbol and allows the user to search for another user to mention in their note.
    var showMentionsAutocomplete = false {
        didSet {
            if showMentionsAutocomplete {
                analytics.mentionsAutocompleteOpened()
            }
        }
    }

    /// The view the user will use for editing. Should only be set by ``NoteTextEditor/NoteUITextViewRepresentable``.
    var textView: UITextView? {
        didSet {
            textView?.delegate = self
        }
    }
    
    /// Whether the user has entered any text.
    var isEmpty = true

    /// The attributed text the user has entered.
    var text: AttributedString? {
        if let textView {
            return AttributedString(textView.attributedText)
        } else {
            return nil
        }
    }
    
    /// The attributed string attributes that should be applied to normal text the user types in the text field. 
    private var defaultStringAttributes: [NSAttributedString.Key: Any]
    
    init(font: UIFont = .preferredFont(forTextStyle: .body), foregroundColor: UIColor = .primaryTxt) {
        self.defaultStringAttributes = [
            .font: font,
            .foregroundColor: foregroundColor
        ]
    }
    
    // MARK: - Mutating Text
    
    /// Inserts the name of an author at the current cursor position with a nostr link attached as an attribute.
    func insertMention(of author: Author) {
        guard let textView else { return }
        self.insertMention(of: author, at: textView.selectedRange) 
    }
    
    /// Appends the given string at the end of the text the user has entered.
    func append(text: String) {
        guard let textView else {
            return
        }
        
        let range = NSRange(location: textView.attributedText.length, length: 0)
        let appendedAttributedString = NSAttributedString(
            string: text,
            attributes: defaultStringAttributes
        )
        
        let attributedString = NSMutableAttributedString(attributedString: textView.attributedText)
        attributedString.replaceCharacters(in: range, with: appendedAttributedString)
        textView.attributedText = attributedString
        textView.selectedRange.location += appendedAttributedString.length

        ///  Check if `@` was appended and show the mentionsAutoComplete list.
        guard text == "@" else { return }
        showMentionsAutocomplete = true
    }
    
    /// Appends the given URL and adds the default link styling attributes. Will append a space before the link 
    /// if needed.
    func append(_ url: URL) {
        guard let text = textView?.attributedText else { return }
        
        if let lastCharacter = text.string.last, !lastCharacter.isWhitespace {
            append(text: " ")
        }
        
        let range = NSRange(location: text.length, length: 0)
        insert(text: url.absoluteString, link: url.absoluteString, at: range)
    }
    
    // MARK: - UITextViewDelegate
    
    func textViewDidChange(_ textView: UITextView) {
        updateIntrinsicHeight(view: textView)
        isEmpty = textView.attributedText.length == 0
    }
        
    func textView(
        _ textView: UITextView, 
        primaryActionFor textItem: UITextItem, 
        defaultAction: UIAction
    ) -> UIAction? {
        nil
    }
    
    func textView(
        _ textView: UITextView,
        shouldChangeTextIn nsRange: NSRange,
        replacementText text: String
    ) -> Bool {
        let handledChange = removeLinkAttributesUnderCursor(selectedRange: nsRange, in: textView, newText: text)
        if handledChange {
            return false
        }
        textView.typingAttributes = defaultStringAttributes
        
        if text == "@" {
            let showedAutocomplete = checkForMentionsAutocomplete(in: textView, at: nsRange)
            if showedAutocomplete {
                return true
            }
        } else if text.count > 1 {
            let insertedNostrLink = handleNostrIdentifiers(in: text, textView: textView)
            if insertedNostrLink {
                return false
            }
        } 
        
        return true
    }

    // MARK: - Helpers 
    
    /// Calculates the height that fits all entered text, and updates `intrinsicHeight` with this property. This is 
    /// done to work around some incompatibilities between UIKit and SwiftUI where the UITextView won't expand properly.
    func updateIntrinsicHeight(view: UIView) {
        let newSize = view.sizeThatFits(CGSize(width: view.frame.width, height: .greatestFiniteMagnitude))
        guard intrinsicHeight != newSize.height else { return }
        DispatchQueue.main.async { // call in next render cycle.
            self.intrinsicHeight = newSize.height
        }
    }
    
    /// Inserts the name of an author at the given range with a nostr link attached as an attribute. This function
    /// assumes the cursor is directly after an '@' and will replace that too.
    private func insertMention(of author: Author, at range: NSRange) {
        guard let textView, let url = author.uri else {
            return
        }
        
        let rangeIncludingAmpersand = NSRange(
            location: max(range.location - 1, 0), 
            length: min(range.length + 1, textView.attributedText.length)
        )
        insert(text: "@\(author.safeName)", link: url.absoluteString, at: rangeIncludingAmpersand)
    }
    
    /// Handles the user pasting an npub at the given range.
    private func insertMention(npub: String, range: NSRange) {
        insert(text: npub.prefix(10).appending("..."), link: "nostr:\(npub)", at: range)
    }
    
    /// Handles the user pasting an note link at the given range. 
    private func insertMention(note: String, range: NSRange) {
        insert(text: note.prefix(10).appending("..."), link: "nostr:\(note)", at: range)
    }
    
    /// Inserts a string at the given range and adds the link attribute with the given `link`.
    private func insert(text: String, link: String, at range: NSRange) {
        guard let textView else {
            return
        }
        
        let linkAttributes = defaultStringAttributes.merging(
            [NSAttributedString.Key.link: link], 
            uniquingKeysWith: { _, key in key }
        )
        let link = NSMutableAttributedString(
            string: text,
            attributes: linkAttributes
        )
        let space = NSAttributedString(string: " ", attributes: defaultStringAttributes)
        link.append(space)
        
        let attributedString = NSMutableAttributedString(attributedString: textView.attributedText)
        attributedString.replaceCharacters(in: range, with: link)
        textView.attributedText = attributedString
        textView.selectedRange.location = range.location + link.length
        isEmpty = false

        // Update the textview height after inserting text
        updateIntrinsicHeight(view: textView)
    }
    
    /// Takes the same arguments as `textView(_:shouldChangeTextIn:replacementText:)` and detects the case where the 
    /// user is typing inside a link (like a mention of another author). If this is the case we remove the link 
    /// attribute from the link and insert the given `newText` and return true. Otherwise this will return `false`.
    private func removeLinkAttributesUnderCursor(
        selectedRange: NSRange, 
        in textView: UITextView, 
        newText: String
    ) -> Bool {
        let attributedText = textView.attributedText!
        if attributedText.length > 0, selectedRange.location < attributedText.length || newText.isEmpty {
            var rangeOfLink = NSRange()
            let location = newText.isEmpty ? max(selectedRange.location, 0) : selectedRange.location
            let link = attributedText.attribute(
                .link, 
                at: location, 
                longestEffectiveRange: &rangeOfLink, 
                in: NSRange(location: 0, length: attributedText.length)
            )
            
            if link != nil {
                let newAttributesString = NSMutableAttributedString(attributedString: attributedText)
                newAttributesString.removeAttribute(.link, range: rangeOfLink)
                newAttributesString.replaceCharacters(in: selectedRange, with: newText)
                textView.attributedText = newAttributesString
                textView.selectedRange = NSRange(
                    location: selectedRange.location + (newText as NSString).length, 
                    length: 0
                )
                return true
            }
        }
        
        return false
    }
        
    /// Call this when the user has typed a '@' and it will trigger the mentions autocomplete to open if appropriate.
    /// - Returns: `true` if it opened the mentions autocomplete.
    private func checkForMentionsAutocomplete(in textView: UITextView, at range: NSRange) -> Bool {
        if textView.text.count == 0 {
            showMentionsAutocomplete = true
            return true
        } else {
            let lastCharacter = (textView.text as NSString).character(at: max(range.location - 1, 0))
            if let scalar = UnicodeScalar(lastCharacter), CharacterSet.whitespacesAndNewlines.contains(scalar) {
                showMentionsAutocomplete = true
                return true
            }
        }
        return false
    }
    
    /// Checks to see if `text` is a valid `NostrIdentifier` and inserts it into the given `textView` as a link if 
    /// it is. 
    /// - Returns: `true` if it inserted a link.
    private func handleNostrIdentifiers(in text: String, textView: UITextView) -> Bool {
        do {
            _ = try NostrIdentifier.decode(bech32String: text)
            insert(text: text.prefix(10).appending("..."), link: "nostr:\(text)", at: textView.selectedRange)
            DispatchQueue.main.async { textView.selectedRange.location += (text as NSString).length }
            return true
        } catch {
            return false
        }
    }
}
