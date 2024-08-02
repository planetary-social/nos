import Foundation
import SwiftUI
import UIKit

@Observable class NoteEditorController: NSObject, UITextViewDelegate {

    /// The height that fits all entered text. This value will be updated by NoteTextViewRepresentable automatically, 
    /// and should be used to set the frame of NoteTextViewRepresentable from SwiftUI. This is done to work around some
    /// incompatibilities between UIKit and SwiftUI where the UITextView won't expand properly.
    var intrinsicHeight: CGFloat = 0
    
    var showMentionsSearch = false
    
    var textView: UITextView? {
        didSet {
            textView?.delegate = self
        }
    }
    
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
    
    init(font: UIFont = .preferredFont(forTextStyle: .body), foregroundColor: UIColor = .primaryTxt) {
        let defaultAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: foregroundColor
        ]
        self.defaultNSAttributes = defaultAttributes
    }
    
    // MARK: - Public Interface
    
    func insertMention(of author: Author) {
        guard let textView else { return }
        self.insertMention(of: author, at: textView.selectedRange) 
    }
    
    func append(text: String) {
        guard let textView else {
            return
        }
        
        let range = NSRange(location: textView.attributedText.length, length: 0)
        let appendedAttributedString = NSAttributedString(
            string: text,
            attributes: defaultNSAttributes
        )
        
        let attributedString = textView.attributedText.mutableCopy() as! NSMutableAttributedString
        attributedString.replaceCharacters(in: range, with: appendedAttributedString)
        textView.attributedText = attributedString
        textView.selectedRange.location += appendedAttributedString.length
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
        let attributedText = textView.attributedText!
        let selectedRange = textView.selectedRange
        if attributedText.length > 0, (selectedRange.location < attributedText.length || text.isEmpty) {
            var rangeOfLink = NSRange()
            var location = text.isEmpty ? max(selectedRange.location - 1, 0) : selectedRange.location
            let link = attributedText.attribute(.link, at: location, longestEffectiveRange: &rangeOfLink, in: NSRange(location: 0, length: attributedText.length))
            
            if let link {
                let newAttributesString = (attributedText.mutableCopy() as! NSMutableAttributedString)
                newAttributesString.removeAttribute(.link, range: rangeOfLink)
                newAttributesString.replaceCharacters(in: nsRange, with: text)
                textView.attributedText = newAttributesString
                textView.selectedRange = NSRange(location: selectedRange.location + (text as NSString).length, length: 0)
                return false
            }
        }
        
        textView.typingAttributes = defaultNSAttributes
        
        if text == "@" {
            if textView.text.count == 0 {
                showMentionsSearch = true
                return true
            } else if textView.text.count > 0 {
                let lastCharacter = (textView.text as NSString).character(at: max(nsRange.location - 1, 0))
                if let scalar = UnicodeScalar(lastCharacter), CharacterSet.whitespacesAndNewlines.contains(scalar) {
                    showMentionsSearch = true
                    return true
                }
            }
        } else if text.count > 1 {
            do {
                let identifier = try NostrIdentifier.decode(bech32String: text)
                switch identifier {
                case .npub:
                    insertMention(npub: text, range: textView.selectedRange)
                    DispatchQueue.main.async { textView.selectedRange.location += (text as NSString).length }
                    return false
                case .note:
                    insertMention(note: text, range: textView.selectedRange)
                    DispatchQueue.main.async { textView.selectedRange.location += (text as NSString).length }
                    return false
                // TODO: handle other cases
                default:
                    return true
                }
            } catch {
                return true
            }
        } 
        
        return true
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
            length: min(range.length + 1, textView.attributedText.length)
        )
        sjdfl;kasjdf      
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
        textView.selectedRange.location = range.location + link.length
    }
}
