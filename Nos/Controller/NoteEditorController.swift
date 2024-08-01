import Foundation
import SwiftUI
import UIKit

@Observable class NoteEditorController: NSObject, UITextViewDelegate {

    /// The height that fits all entered text. This value will be updated by NoteTextViewRepresentable automatically, 
    /// and should be used to set the frame of NoteTextViewRepresentable from SwiftUI. This is done to work around some
    /// incompatibilities between UIKit and SwiftUI where the UITextView won't expand properly.
    var intrinsicHeight: CGFloat = 0
    
    var showMentionsSearch = false
    
    var textView: UITextView?
    
    var isEmpty: Bool = true
    
    var text: AttributedString? {
        if let textView {
            return AttributedString(textView.attributedText)
        } else {
            return nil
        }
    }
    
    var defaultAttributes: AttributeContainer {
        AttributeContainer(defaultNSAttributes)
    }
    
    var defaultNSAttributes: [NSAttributedString.Key: Any]
    
    // MARK: - Init
    
    init(font: UIFont = .preferredFont(forTextStyle: .body), foregroundColor: UIColor = .primaryTxt) {
        let defaultAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: foregroundColor
        ]
        self.defaultNSAttributes = defaultAttributes
    }
    
    func insertMention(of author: Author) {
        guard let textView else { return }
        self.insertMention(of: author, at: textView.selectedRange) 
    }
    
    func append(text: String) {
        guard let textView else {
            return
        }
        
        let range = NSRange(location: text.count, length: 0)
        let appendedAttributedString = NSAttributedString(
            string: text,
            attributes: defaultNSAttributes
        )
        
        let attributedString = textView.attributedText.mutableCopy() as! NSMutableAttributedString
        attributedString.replaceCharacters(in: range, with: appendedAttributedString)
        textView.attributedText = attributedString
    }
    
    /// Appends the given URL and adds the default styling attributes. Will append a space before the link if needed.
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
        isEmpty = textView.attributedText.isEmpty
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
        textView.typingAttributes = defaultNSAttributes
        if text == "@" {
            showMentionsSearch = true
            return true
            // TODO: handle inserting mention even when text is selected
        } else if text.count > 1 {
            do {
                let identifier = try NostrIdentifier.decode(bech32String: text)
                switch identifier {
                case .npub:
                    insertMention(npub: text, range: textView.selectedRange)
                    DispatchQueue.main.async { textView.selectedRange.location += text.count }
                    return false
                case .note:
                    insertMention(note: text, range: textView.selectedRange)
                    DispatchQueue.main.async { textView.selectedRange.location += text.count }
                    return false
                // TODO: handle other cases
                default:
                    return true
                }
            } catch {
                return true
            }
        } else {
            return true
        }
    }
    
    // MARK: - Helpers 
    
    /// Calculates the height that fits all entered text, and updates $intrinsicHeight with this property. This is 
    /// done to work around some incompatibilities between UIKit and SwiftUI where the UITextView won't expand properly.
    func updateIntrinsicHeight(view: UIView) {
        let newSize = view.sizeThatFits(CGSize(width: view.frame.width, height: .greatestFiniteMagnitude))
        guard intrinsicHeight != newSize.height else { return }
        DispatchQueue.main.async { // call in next render cycle.
            self.intrinsicHeight = newSize.height
        }
    }
    
    private func insertMention(of author: Author, at range: NSRange) {
        guard let textView, let url = author.uri else {
            return
        }
        
        let rangeIncludingAmpersand = NSRange(
            location: max(range.location - 1, 0), 
            length: min(range.length + 1, textView.text.count)
        )
        
        insert(text: "@\(author.safeName)", link: url.absoluteString, at: rangeIncludingAmpersand)
    }
    
    private func insertMention(npub: String, range: NSRange) {
        insert(text: npub.prefix(10).appending("..."), link: "nostr:\(npub)", at: range)
    }
    
    /// Inserts the mention of a note as a link at the given index of the string.
    private func insertMention(note: String, range: NSRange) {
        insert(text: note.prefix(10).appending("..."), link: "nostr:\(note)", at: range)
    }
    
    private func insert(text: String, link: String, at range: NSRange) {
        guard let textView else {
            return
        }
        
        let linkAttributes = defaultNSAttributes.merging(
            [NSAttributedString.Key.link: link], 
            uniquingKeysWith: { _, key in key }
        )
        let link = NSAttributedString(
            string: text,
            attributes: linkAttributes
        )
        
        let attributedString = textView.attributedText.mutableCopy() as! NSMutableAttributedString
        attributedString.replaceCharacters(in: range, with: link)
        textView.attributedText = attributedString
    }
}
