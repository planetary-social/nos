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
struct EditableText: UIViewRepresentable {

    typealias UIViewType = UITextView

    @Binding var attributedText: AttributedString
    @State private var selectedRange = NSRange(location: 0, length: 0)

    private var guid: UUID
    private var font = UIFont.preferredFont(forTextStyle: .body)
    private var insets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)

    init(_ attributedText: Binding<AttributedString>, guid: UUID) {
        _attributedText = attributedText
        self.guid = guid
    }

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.attributedText = NSAttributedString(attributedText)
        view.isUserInteractionEnabled = true
        view.isScrollEnabled = false
        view.isEditable = true
        view.isSelectable = true
        view.tintColor = .accent
        view.textColor = .secondaryText
        view.font = font
        view.backgroundColor = .clear
        view.delegate = context.coordinator

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
            guard let url = author.deepLink else {
                return
            }
            let mention = NSAttributedString(
                string: "@\(author.safeName)",
                attributes: view?.typingAttributes.merging(
                    [NSAttributedString.Key.link: url],
                    uniquingKeysWith: { lhs, _ in lhs }
                )
            )

            let mutableAttributedString = NSMutableAttributedString(attributedString: nsAttributedString)
            mutableAttributedString.replaceCharacters(
                in: NSRange(location: selectedRange.location - 1, length: 1),
                with: mention
            )
            attributedText = AttributedString(mutableAttributedString)
            selectedRange.location += mention.length - 1
        }

        return view
    }

    static func dismantleUIView(_ uiView: UITextView, coordinator: Coordinator) {
        if let observer = coordinator.observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    var nsAttributedString: NSAttributedString {
        NSAttributedString(attributedText)
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.attributedText = NSAttributedString(attributedText)
        uiView.selectedRange = selectedRange
        uiView.typingAttributes = [
            .font: font,
            .foregroundColor: Color.secondaryText
        ]
        uiView.invalidateIntrinsicContentSize()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $attributedText, selectedRange: $selectedRange)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var observer: NSObjectProtocol?
        var text: Binding<AttributedString>
        var selectedRange: Binding<NSRange>

        init(text: Binding<AttributedString>, selectedRange: Binding<NSRange>) {
            self.text = text
            self.selectedRange = selectedRange
        }

        func textViewDidChange(_ textView: UITextView) {
            text.wrappedValue = AttributedString(textView.attributedText)
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            DispatchQueue.main.async {
                self.selectedRange.wrappedValue = textView.selectedRange
            }
        }
    }
}

extension Notification.Name {
    public static let mentionAddedNotification = Notification.Name("mentionAddedNotification")
}

struct EditableText_Previews: PreviewProvider {

    @State static var attributedString = AttributedString("Hello")
    @State static var oldText = AttributedString("Hello")

    static var previews: some View {
        EditableText($attributedString, guid: UUID())
            .onChange(of: attributedString) { newValue in
                let newString = String(newValue.characters)
                let oldString = String(oldText.characters)
                let difference = newString.difference(from: oldString)
                guard difference.count == 1, let change = difference.first else {
                    oldText = newValue
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
                oldText = newValue
            }
            .previewLayout(.sizeThatFits)
    }
}
