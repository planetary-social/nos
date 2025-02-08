import Foundation
import SwiftUI
import UIKit

extension NoteTextEditor {
    /// A UIViewRepresentable that wraps a UITextView and configures it for composing a Nostr note. The UITextView works
    /// with the provided `NoteEditorController` to interface with other SwiftUI views, supporting autocomplete of 
    /// mentions, dynamic sizing, appending uploaded file URLs, etc.
    /// 
    /// This view is designed to be used inside `NoteTextEditor`.  
    struct NoteUITextViewRepresentable: UIViewRepresentable {
        
        @State private var width: CGFloat
        
        /// Whether we should present the keyboard when this view is shown. Unfortunately we can't rely on FocusState as
        /// it isn't working on macOS.
        private let showKeyboard: Bool
        
        private let font = UIFont.preferredFont(forTextStyle: .body)
        
        private let controller: NoteEditorController
        
        init(
            controller: NoteEditorController,
            showKeyboard: Bool = false
        ) {
            self.controller = controller
            self.showKeyboard = showKeyboard
            _width = .init(initialValue: 0)
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
            view.textContainer.maximumNumberOfLines = 0
            view.textContainer.lineBreakMode = .byWordWrapping
            view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            view.typingAttributes = [
                .font: font,
                .foregroundColor: UIColor.primaryTxt
            ]
            
            if ProcessInfo.processInfo.isiOSAppOnMac {
                view.autocorrectionType = .no
            }
            
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
            controller.updateIntrinsicHeight(view: uiView)
        }
        
        func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
            if width != uiView.frame.size.width {
                DispatchQueue.main.async { // call in next render cycle.
                    width = uiView.frame.size.width
                    controller.updateIntrinsicHeight(view: uiView)
                }
            } else if width == 0,
                uiView.frame.size.width == 0, 
                let proposedWidth = proposal.width, 
                proposedWidth > 0,
                proposedWidth < CGFloat.infinity {
                DispatchQueue.main.async { // call in next render cycle.
                    uiView.frame.size.width = proposedWidth
                    controller.updateIntrinsicHeight(view: uiView)
                }
            }
            return nil
        }
    }
}

struct NoteTextViewRepresentable_Previews: PreviewProvider {

    @State static var controller = NoteEditorController()

    static var previews: some View {
        NoteTextEditor.NoteUITextViewRepresentable(
            controller: controller,
            showKeyboard: false
        )
        .previewLayout(.sizeThatFits)
    }
}
