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

    @Binding var attributedText: NSAttributedString
    @Binding var calculatedHeight: CGFloat

    private var guid: UUID
    private var font = UIFont.preferredFont(forTextStyle: .body)
    private var insets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)

    init(_ attributedText: Binding<NSAttributedString>, guid: UUID, calculatedHeight: Binding<CGFloat>? = nil) {
        _attributedText = attributedText
        self.guid = guid
        _calculatedHeight = calculatedHeight ?? .constant(0)
    }

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.attributedText = attributedText
        view.isUserInteractionEnabled = true
        view.isScrollEnabled = false
        view.isEditable = true
        view.isSelectable = true
        view.tintColor = .accent
        view.textColor = .secondaryText
        view.font = font
        view.backgroundColor = .clear
        view.delegate = context.coordinator
        view.textContainer.maximumNumberOfLines = 0
        view.textContainer.lineBreakMode = .byWordWrapping
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
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
            guard let url = author.uri else {
                return
            }
            guard let selectedRange = view?.selectedRange else {
                return
            }
            let mention = NSAttributedString(
                string: "@\(author.safeName)",
                attributes: view?.typingAttributes.merging(
                    [NSAttributedString.Key.link: url],
                    uniquingKeysWith: { lhs, _ in lhs }
                )
            )

            let mutableAttributedString = NSMutableAttributedString(attributedString: attributedText)
            mutableAttributedString.replaceCharacters(
                in: NSRange(location: selectedRange.location - 1, length: 1),
                with: mention
            )
            view?.attributedText = mutableAttributedString
            view?.selectedRange.location += mention.length - 1
        }

        return view
    }

    static func dismantleUIView(_ uiView: UITextView, coordinator: Coordinator) {
        if let observer = coordinator.observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.attributedText = attributedText
        uiView.typingAttributes = [
            .font: font,
            .foregroundColor: UIColor.primaryTxt
        ]
        Self.recalculateHeight(view: uiView, result: $calculatedHeight)
    }

    fileprivate static func recalculateHeight(view: UIView, result: Binding<CGFloat>) {
        let newSize = view.sizeThatFits(CGSize(width: view.frame.width, height: .greatestFiniteMagnitude))
        guard result.wrappedValue != newSize.height else { return }
        DispatchQueue.main.async { // call in next render cycle.
            result.wrappedValue = newSize.height
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $attributedText)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var observer: NSObjectProtocol?
        var text: Binding<NSAttributedString>

        init(text: Binding<NSAttributedString>) {
            self.text = text
        }

        func textViewDidChange(_ textView: UITextView) {
            text.wrappedValue = textView.attributedText
            
            // Update the selected range to the end of the newly added text
            let newSelectedRange = NSRange(
                location: textView.selectedRange.location + textView.selectedRange.length, 
                length: 0
            )
            textView.selectedRange = newSelectedRange
        }
    }
}

extension Notification.Name {
    public static let mentionAddedNotification = Notification.Name("mentionAddedNotification")
}

struct EditableText_Previews: PreviewProvider {

    @State static var attributedString = NSAttributedString("Hello")
    @State static var oldText = NSAttributedString("Hello")
    @State static var calculatedHeight: CGFloat = 44

    static var previews: some View {
        EditableText($attributedString, guid: UUID(), calculatedHeight: $calculatedHeight)
            .onChange(of: attributedString) { newValue in
                let newString = newValue.string
                let oldString = oldText.string
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
