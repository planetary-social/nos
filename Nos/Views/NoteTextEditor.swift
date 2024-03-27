import SwiftUI

/// A text editor for composing Nostr notes. Supports autocomplete of mentions.
struct NoteTextEditor: View {
    
    @Binding var text: EditableNoteText
    
    /// The height of the EditableNoteText that fits all entered text.
    @State var intrinsicHeight: CGFloat = 0
    
    /// The smallest size of EditableNoteText
    var minHeight: CGFloat
    
    var placeholder: LocalizedStringResource
    @State private var guid = UUID()
    
    /// State containing the offset (index) of text when the user is mentioning someone
    ///
    /// When we detect the user typed a '@', we save the position of that character here and open a screen
    /// that lets the user select someone to mention, then we can replace this character with the full mention.
    @State private var mentionOffset: Int?
    
    /// Setting this to true will pop up the mention list to select an author to mention in the text editor.
    private var showAvailableMentions: Binding<Bool> {
        Binding {
            mentionOffset != nil
        } set: { _ in
            mentionOffset = nil
        }
    }
    
    var body: some View {
        NoteTextViewRepresentable($text, guid: guid, intrinsicHeight: $intrinsicHeight, showKeyboard: true)
            .frame(maxWidth: .infinity)
            .frame(height: max(minHeight, intrinsicHeight, 0))
            .placeholder(when: text.isEmpty, placeholder: {
                VStack {
                    Text(placeholder)
                        .foregroundColor(.secondaryTxt)
                        .padding(.top, 10)
                        .padding(.leading, 6)
                    Spacer()
                }
            })
            .padding(.leading, 6)
            .background { Color.appBg }
            .onChange(of: text) { oldText, newText in
                let difference = newText.difference(from: oldText)
                guard difference.count == 1, let change = difference.first else {
                    return
                }
                switch change {
                case .insert(let offset, let element, _):
                    if element == "@" {
                        let precedingCharacter = newText.character(before: offset) ?? Character("\n")
                        if precedingCharacter.isNewline || precedingCharacter.isWhitespace {
                            mentionOffset = offset
                        }
                    }
                default:
                    break
                }
            }
            .sheet(isPresented: showAvailableMentions) {
                NavigationStack {
                    AuthorListView(isPresented: showAvailableMentions) { author in
                        guard let offset = mentionOffset else {
                            return
                        }
                        insertMention(at: offset, author: author)
                    }
                }
            }
    }
    
    private func insertMention(at offset: Int, author: Author) {
        // We communicate with the underlying EditableText using NSNotification
        NotificationCenter.default.post(
            name: .mentionAddedNotification,
            object: nil,
            userInfo: ["author": author, "guid": guid]
        )
        mentionOffset = nil
    }
}

struct NoteTextEditor_Previews: PreviewProvider {
    
    @State static var text = EditableNoteText()
    static var placeholder: LocalizedStringResource = .localizable.newNotePlaceholder

    static var previews: some View {
        VStack {
            NoteTextEditor(
                text: $text, 
                minHeight: 100,
                placeholder: placeholder
            )
            Spacer()
        }
    }
}
