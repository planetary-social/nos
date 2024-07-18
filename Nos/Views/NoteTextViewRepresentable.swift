import Foundation
import SwiftUI
import UIKit

/// A UIViewRepresentable that wraps a UITextView meant to be used in place of TextEditor when rich text formatting is
/// desirable.
///
/// This view also listens for the .mentionAddedNotification and inserts markdown links 
/// to nostr objects when it is received.
struct NoteTextViewRepresentable: UIViewRepresentable {

    typealias UIViewType = UITextView

    @Binding var text: EditableNoteText
    
    /// The height that fits all entered text. This value will be updated by NoteTextViewRepresentable automatically, 
    /// and should be used to set the frame of NoteTextViewRepresentable from SwiftUI. This is done to work around some
    /// incompatibilities between UIKit and SwiftUI where the UITextView won't expand properly.
    @Binding var intrinsicHeight: CGFloat
    @State var width: CGFloat
    
    /// Whether we should present the keyboard when this view is shown. Unfortunately we can rely on FocusState as 
    /// it isn't working on macOS.
    private var showKeyboard: Bool

    /// An ID for this view. Only .mentionAddedNotifications matching this ID will be processed.
    private var guid: UUID
    private var font = UIFont.preferredFont(forTextStyle: .body)

    init(
        _ text: Binding<EditableNoteText>, 
        guid: UUID, 
        intrinsicHeight: Binding<CGFloat>, 
        showKeyboard: Bool = false
    ) {
        self.guid = guid
        self.showKeyboard = showKeyboard
        _width = .init(initialValue: 0)
        _text = text
        _intrinsicHeight = intrinsicHeight
    }

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView(usingTextLayoutManager: false)
        view.attributedText = text.nsAttributedString
        view.isUserInteractionEnabled = true
        view.isScrollEnabled = false
        view.isEditable = true
        view.isSelectable = true
        view.tintColor = .accent
        view.textColor = .secondaryTxt
        view.font = font
        view.backgroundColor = .clear
        view.delegate = context.coordinator
        view.textContainer.maximumNumberOfLines = 0
        view.textContainer.lineBreakMode = .byWordWrapping
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.autocorrectionType = .no // temporary fix to work around mac bug
        
        context.coordinator.observer = NotificationCenter.default.addObserver(
            forName: .mentionAddedNotification,
            object: nil,
            queue: .main
        ) { [weak view] notification in
            guard let author = notification.userInfo?["author"] as? Author else {
                return
            }
            guard let recGUID = notification.userInfo?["guid"] as? UUID, recGUID == guid else {
                return
            }
            guard let selectedNSRange = view?.selectedRange,
                let range = Range(selectedNSRange, in: text.attributedString) else {
                return
            }
            text.insertMention(of: author, at: range.lowerBound)
            view?.selectedRange.location += (view?.attributedText.length ?? 1) - 1
        }
        
        if showKeyboard {
            Task {
                try await Task.sleep(for: .milliseconds(200))
                view.becomeFirstResponder()
            }
        }

        return view
    }

    static func dismantleUIView(_ uiView: UITextView, coordinator: Coordinator) {
        if let observer = coordinator.observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.attributedText = text.nsAttributedString
        uiView.typingAttributes = text.defaultNSAttributes
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
        Coordinator(text: $text)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var observer: NSObjectProtocol?
        var text: Binding<EditableNoteText>

        init(text: Binding<EditableNoteText>) {
            self.text = text
        }

        func textViewDidChange(_ textView: UITextView) {
            text.wrappedValue = EditableNoteText(nsAttributedString: textView.attributedText)
            
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
            if text.count > 1, let range = Range(nsRange, in: self.text.wrappedValue.attributedString) {
                do {
                    let identifier = try NostrIdentifier.decode(bech32String: text)
                    switch identifier {
                    case .npub(let publicKey):
                        self.text.wrappedValue.insertMention(npub: text, at: range)
                        return false
                    case .note(let eventID):
                        self.text.wrappedValue.insertMention(note: text, at: range)
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
    }
}

extension Notification.Name {
    public static let mentionAddedNotification = Notification.Name("mentionAddedNotification")
}

struct NoteTextViewRepresentable_Previews: PreviewProvider {

    @State static var attributedString = EditableNoteText(string: "Hello")
    @State static var intrinsicHeight: CGFloat = 0

    static var previews: some View {
        NoteTextViewRepresentable($attributedString, guid: UUID(), intrinsicHeight: $intrinsicHeight)
            .onChange(of: attributedString) { oldText, newText in
                let difference = newText.difference(from: oldText)
                guard difference.count == 1, let change = difference.first else {
                    return
                }
                switch change {
                case .insert(let offset, let element, _):
                    if element == "a" {
                        print("mention inserted at \(offset)")
                    }
                default:
                    break
                }
            }
            .previewLayout(.sizeThatFits)
    }
}
