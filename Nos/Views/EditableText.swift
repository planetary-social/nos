//
//  EditableText.swift
//  Nos
//
//  Created by Martin Dutra on 5/4/23.
//

import Foundation
import SwiftUI
import UIKit

/// A ViewRepresentable that wraps a UILabel meant to be used in place of Text when selection word by word is desired.
///
/// SwiftUI's Text cannot be configured to be selected in a word by word basis, just the whole text, wrapping up a
/// UILabel achieves this. Also, this is configured to use a monospaced font as the intended use at the moment is
/// when showing a Source Message.
struct EditableText: UIViewRepresentable {

    @Binding var attributedText: AttributedString

    private var font = UIFont.preferredFont(forTextStyle: .body)
    private var insets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)

    init(_ attributedText: Binding<AttributedString>) {
        _attributedText = attributedText
    }

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.attributedText = NSAttributedString(attributedText)
        view.isUserInteractionEnabled = true
        view.isEditable = true
        view.isSelectable = true
        view.tintColor = .accent
        view.textColor = .secondaryTxt
        view.font = font
        view.backgroundColor = .clear
        view.delegate = context.coordinator
        return view
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.attributedText = NSAttributedString(attributedText)
        uiView.typingAttributes = [
            .font: font,
            .foregroundColor: Color.secondaryTxt
        ]
    }

    func makeCoordinator() -> Coordinator {
        Coordinator($attributedText)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var text: Binding<AttributedString>

        init(_ text: Binding<AttributedString>) {
            self.text = text
        }

        func textViewDidChange(_ textView: UITextView) {
            self.text.wrappedValue = AttributedString(textView.attributedText)
            
        }
    }
}

struct EditableText_Previews: PreviewProvider {

    @State static var attributedString = AttributedString("Hello")
    @State static var oldText = AttributedString("Hello")

    static var previews: some View {
        EditableText($attributedString)
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
