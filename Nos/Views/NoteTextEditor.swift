import SwiftUI
import Logger

/// A text editor for composing Nostr notes. Supports autocomplete of mentions.
struct NoteTextEditor: View {
    
    var initialContents: String?
    
    @Binding private var controller: NoteEditorController
    
    /// The height of the EditableNoteText that fits all entered text.
    @State private var intrinsicHeight: CGFloat = 0
    
    /// The smallest size of EditableNoteText
    var minHeight: CGFloat
    
    var placeholder: LocalizedStringResource
    
    /// State containing the offset (index) of text when the user is mentioning someone
    ///
    /// When we detect the user typed a '@', we save the position of that character here and open a screen
    /// that lets the user select someone to mention, then we can replace this character with the full mention.
    @State private var mentionOffset: Int?
    
    init(
        controller: Binding<NoteEditorController>,
        initialContents: String? = nil, 
        minHeight: CGFloat, 
        placeholder: LocalizedStringResource
    ) {
        self._controller = controller
        self.initialContents = initialContents
        self.minHeight = minHeight
        self.placeholder = placeholder
    }
    
    var body: some View {
        // TODO: set initialContents
        NoteTextViewRepresentable(
            controller: controller,
            intrinsicHeight: $intrinsicHeight, 
            showKeyboard: true
        )
            .frame(maxWidth: .infinity)
            .frame(height: max(minHeight, intrinsicHeight, 0))
        // TODO: add placeholder
//            .placeholder(when: text.isEmpty, placeholder: {
//                VStack {
//                    Text(placeholder)
//                        .foregroundColor(.secondaryTxt)
//                        .padding(.top, 10)
//                        .padding(.leading, 6)
//                    Spacer()
//                }
//            })
            .padding(.leading, 6)
            .background { Color.appBg }
//            .onChange(of: text) { oldText, newText in
//                let difference = newText.difference(from: oldText)
//                guard difference.count == 1, let change = difference.first else {
//                    return
//                }
//                switch change {
//                case .insert(let offset, let element, _):
//                    if element == "@" {
//                        let precedingCharacter = newText.character(before: offset) ?? Character("\n")
//                        if precedingCharacter.isNewline || precedingCharacter.isWhitespace {
//                            mentionOffset = offset
//                        }
//                    }
//                default:
//                    break
//                }
//            }
            .sheet(isPresented: $controller.showMentionsSearch) {
                NavigationStack {
                    AuthorListView(isPresented: $controller.showMentionsSearch) { [weak controller] author in
                        /// Guard against double presses
                        guard let controller, controller.showMentionsSearch else { return }
                        
                        controller.insertMention(of: author)
                        controller.showMentionsSearch = false
                    }
                }
            }
    }
}

struct NoteTextEditor_Previews: PreviewProvider {
    
    @State static var controller = NoteEditorController()
    static var placeholder: LocalizedStringResource = .localizable.newNotePlaceholder

    static var previews: some View {
        NavigationStack {
            NoteTextEditor(
                controller: $controller,
                initialContents: "", 
                minHeight: 100,
                placeholder: placeholder
            )
            Spacer()
        }
    }
}
