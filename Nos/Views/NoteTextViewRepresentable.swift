import Foundation
import SwiftUI
import UIKit

@Observable class NoteEditorController: NSObject, UITextViewDelegate {
    var showMentionsSearch = false
    
    var textView: UITextView?
    
    var text: NSAttributedString {
        textView?.attributedText ?? NSAttributedString(string: "")
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
        if let lastCharacter = text.string.last, !lastCharacter.isWhitespace {
            append(text: " ")
        }
        
        let range = NSRange(location: text.length, length: 0)
        insert(text: url.absoluteString, link: url.absoluteString, at: range)
    }
    
    // MARK: - UITextViewDelegate
    
    func textViewDidChange(_ textView: UITextView) {
//        updateIntrinsicHeight(view: uiView)
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

/// A UIViewRepresentable that wraps a UITextView meant to be used in place of TextEditor when rich text formatting is
/// desirable.
///
/// This view also listens for the .mentionAddedNotification and inserts markdown links 
/// to nostr objects when it is received.
struct NoteTextViewRepresentable: UIViewRepresentable {

    typealias UIViewType = UITextView

    /// The height that fits all entered text. This value will be updated by NoteTextViewRepresentable automatically, 
    /// and should be used to set the frame of NoteTextViewRepresentable from SwiftUI. This is done to work around some
    /// incompatibilities between UIKit and SwiftUI where the UITextView won't expand properly.
    @Binding var intrinsicHeight: CGFloat
    @State var width: CGFloat
    
    /// Whether we should present the keyboard when this view is shown. Unfortunately we can rely on FocusState as 
    /// it isn't working on macOS.
    private var showKeyboard: Bool

    private var font = UIFont.preferredFont(forTextStyle: .body)

    private var controller: NoteEditorController
    
    init(
        controller: NoteEditorController,
        intrinsicHeight: Binding<CGFloat>, 
        showKeyboard: Bool = false
    ) {
        self.controller = controller
        self.showKeyboard = showKeyboard
        _width = .init(initialValue: 0)
        _intrinsicHeight = intrinsicHeight
    }

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView(usingTextLayoutManager: false)
        view.isUserInteractionEnabled = true
        view.isScrollEnabled = false
        view.isEditable = true
        view.isSelectable = true
        view.tintColor = .accent
        view.textColor = .secondaryTxt
        view.font = font
        view.backgroundColor = .clear
        view.delegate = controller
        view.textContainer.maximumNumberOfLines = 0
        view.textContainer.lineBreakMode = .byWordWrapping
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.typingAttributes = [
            .font: font,
            .foregroundColor: UIColor.primaryTxt
        ]
        
        if showKeyboard {
            Task {
                try await Task.sleep(for: .milliseconds(200))
                view.becomeFirstResponder()
            }
        }
        
        controller.textView = view

        return view
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        updateIntrinsicHeight(view: uiView)
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        if width != uiView.frame.size.width {
            DispatchQueue.main.async { // call in next render cycle.
                width = uiView.frame.size.width
                updateIntrinsicHeight(view: uiView)
            }
        } else if width == 0,
            uiView.frame.size.width == 0, 
            let proposedWidth = proposal.width, 
            proposedWidth > 0,
            proposedWidth < CGFloat.infinity {
            DispatchQueue.main.async { // call in next render cycle.
                uiView.frame.size.width = proposedWidth
                updateIntrinsicHeight(view: uiView)
            }
        }
        return nil
    }

    /// Calculates the height that fits all entered text, and updates $intrinsicHeight with this property. This is 
    /// done to work around some incompatibilities between UIKit and SwiftUI where the UITextView won't expand properly.
    fileprivate func updateIntrinsicHeight(view: UIView) {
        let newSize = view.sizeThatFits(CGSize(width: view.frame.width, height: .greatestFiniteMagnitude))
        guard intrinsicHeight != newSize.height else { return }
        DispatchQueue.main.async { // call in next render cycle.
            intrinsicHeight = newSize.height
        }
    }

    func makeCoordinator() -> Coordinator {
        controller
    }
}

extension Notification.Name {
    public static let mentionAddedNotification = Notification.Name("mentionAddedNotification")
}

struct NoteTextViewRepresentable_Previews: PreviewProvider {

    @State static var attributedString = EditableNoteText(string: "Hello")
    @State static var intrinsicHeight: CGFloat = 0
    @State static var controller = NoteEditorController()

    static var previews: some View {
        NoteTextViewRepresentable(
            controller: controller,
            intrinsicHeight: $intrinsicHeight, 
            showKeyboard: false
        )
        .previewLayout(.sizeThatFits)
    }
}
