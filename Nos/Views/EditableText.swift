//
//  EditableText.swift
//  Nos
//
//  Created by Martin Dutra on 5/4/23.
//

import Foundation
import SwiftUI
import UIKit

/// A ViewRepresentable that wraps a UITextView meant to be used in place of TextEditor when rich text formatting is
/// desirable.
///
/// This view also listens for the .mentionAddedNotification and inserts markdown links 
/// to nostr objects when it is received.
struct EditableText: UIViewRepresentable {

    typealias UIViewType = UITextView

    @Binding var text: EditableNoteText
    @State var width: CGFloat

    /// An ID for this view. Only .mentionAddedNotifications matching this ID will be processed.
    private var guid: UUID
    private var font = UIFont.preferredFont(forTextStyle: .body)
    private var insets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)

    init(_ text: Binding<EditableNoteText>, guid: UUID) {
        self.guid = guid
        _width = .init(initialValue: 0)
        _text = text
    }

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
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
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        if width != uiView.frame.size.width {
            DispatchQueue.main.async { // call in next render cycle.
                width = uiView.frame.size.width
            }
        } else if width == 0,
            uiView.frame.size.width == 0, 
            let proposedWidth = proposal.width, 
            proposedWidth > 0,
            proposedWidth < CGFloat.infinity {
            DispatchQueue.main.async { // call in next render cycle.
                uiView.frame.size.width = proposedWidth
            }
        }
        return nil
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
                    let (humanReadablePart, _) = try Bech32.decode(text)
                    if humanReadablePart == Nostr.publicKeyPrefix {
                        self.text.wrappedValue.insertMention(npub: text, at: range)
                        return false
                    } else if humanReadablePart == Nostr.notePrefix {
                        self.text.wrappedValue.insertMention(note: text, at: range)
                        return false
                    }
                    return true
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

struct EditableText_Previews: PreviewProvider {

    @State static var attributedString = EditableNoteText(string: "Hello")

    static var previews: some View {
        EditableText($attributedString, guid: UUID())
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
