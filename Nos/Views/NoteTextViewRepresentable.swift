import Foundation
import SwiftUI
import UIKit

@Observable class NoteEditorController: NSObject, UITextViewDelegate {
    var showMentionsSearch = false
    
    var textView: UITextView?
    
    var text: String? {
        textView?.text
    }
    
    var defaultAttributes: AttributeContainer {
        AttributeContainer(defaultNSAttributes)
    }
    
    var defaultNSAttributes: [NSAttributedString.Key: Any]
    
    // MARK: - Init
    
    init(font: UIFont = .preferredFont(forTextStyle: .body), foregroundColor: UIColor = .primaryTxt) {
        self.defaultNSAttributes = [
            .font: font,
            .foregroundColor: foregroundColor
        ]
    }
    
    func append(text newText: String) {
        guard let textView, let currentAttributedText = textView.attributedText else {
            return
        }
        
        // Create a mutable copy of the current attributed text
        let mutableAttributedText = NSMutableAttributedString(attributedString: currentAttributedText)
        
        // Create a new attributed string with the new text and the typing attributes
        let newAttributedText = NSAttributedString(string: newText, attributes: textView.typingAttributes)
        
        // Append the new attributed string to the mutable attributed string
        mutableAttributedText.append(newAttributedText)
        
        // Set the updated attributed string back to the UITextView
        textView.attributedText = mutableAttributedText
    }
    
    func insertMention(of author: Author) {
        guard let textView else { return }
        self.insertMention(of: author, selectedRange: textView.selectedRange) 
    }
    
    func textViewDidChange(_ textView: UITextView) {
        // Update the selected range to the end of the newly added text
        let newSelectedRange = NSRange(
            location: textView.selectedRange.location + textView.selectedRange.length, 
            length: 0
        )
        textView.selectedRange = newSelectedRange
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
        if text == "@" {
            let selectedRange = textView.selectedRange
            showMentionsSearch = true
            return true
            // TODO: handle inserting mention even when text is selected
        } else if text.count > 1, let range = Range(nsRange, in: textView.text) {
            do {
                let identifier = try NostrIdentifier.decode(bech32String: text)
                switch identifier {
                case .npub(let authorID):
                    insertMention(npub: text, selectedRange: textView.selectedRange)
                    DispatchQueue.main.async { textView.selectedRange.location += text.count }
                    return false
                case .note:
                    insertMention(note: text, selectedRange: textView.selectedRange)
                    DispatchQueue.main.async { textView.selectedRange.location += text.count }
                    return false
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
    
    func insertMention(npub: String, selectedRange: NSRange) {
        guard let textView else {
            return
        }
        
        let attributedString = textView.attributedText.mutableCopy() as! NSMutableAttributedString
        
        // TODO: highlight @
        
        // TODO: merge attributes
//        let attributes = defaultNSAttributes.merging([NSAttributedString.Key.link: url.absoluteString], uniquingKeysWith: { $0 || $1 }) 
        let mention = NSAttributedString(string: npub.prefix(10).appending("..."), attributes: [NSAttributedString.Key.link: "nostr:\(npub)"])
        
        attributedString.replaceCharacters(in: selectedRange, with: mention)
        textView.attributedText = attributedString
        textView.typingAttributes = defaultNSAttributes
    }
    
    func insertMention(of author: Author, selectedRange: NSRange) {
        guard let textView, let url = author.uri else {
            return
        }
        
        let attributedString = textView.attributedText.mutableCopy() as! NSMutableAttributedString
        
        // TODO: highlight @
        
        // TODO: merge attributes
//        let attributes = defaultNSAttributes.merging([NSAttributedString.Key.link: url.absoluteString], uniquingKeysWith: { $0 || $1 }) 
        let mention = NSAttributedString(string: author.safeName, attributes: [NSAttributedString.Key.link: url.absoluteString])
        
        attributedString.replaceCharacters(in: selectedRange, with: mention)
        textView.attributedText = attributedString
        textView.typingAttributes = defaultNSAttributes
    }
    
    /// Inserts the mention of a note as a link at the given index of the string. The `index` should be the index
    /// after a `@` character, which this function will replace.
    func insertMention(note: String, selectedRange: NSRange) {
        guard let textView else {
            return
        }
        
        let attributedString = textView.attributedText.mutableCopy() as! NSMutableAttributedString
        
        // TODO: highlight @
        
        // TODO: merge attributes
        //        let attributes = defaultNSAttributes.merging([NSAttributedString.Key.link: url.absoluteString], uniquingKeysWith: { $0 || $1 }) 
        let mention = NSAttributedString(string: note.prefix(10).appending("..."), attributes: [NSAttributedString.Key.link: "nostr:\(note)"])
        
        attributedString.replaceCharacters(in: selectedRange, with: mention)
        textView.attributedText = attributedString
        textView.typingAttributes = defaultNSAttributes
    }
    
    //    /// Appends the given URL and adds the default styling attributes. Will append a space before the link if needed.
    //    mutating func append(_ url: URL) {
    //        if let lastCharacter = string.last, !lastCharacter.isWhitespace {
    //            append(" ")
    //        }
    //        
    //        attributedString.append(
    //            AttributedString(
    //                url.absoluteString,
    //                attributes: defaultAttributes.merging(
    //                    AttributeContainer([NSAttributedString.Key.link: url.absoluteString])
    //                )
    //            )
    //        ) 
    //    }
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
