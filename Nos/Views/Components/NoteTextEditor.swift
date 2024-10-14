import Logger
import SwiftUI

/// A view similar to `TextEditor` for composing Nostr notes. Supports autocomplete of mentions.
struct NoteTextEditor: View {

    /// A controller for the entered text.
    @Binding private var controller: NoteEditorController

    /// The smallest size of EditableNoteText
    var minHeight: CGFloat

    var placeholder: LocalizedStringResource

    init(controller: Binding<NoteEditorController>, minHeight: CGFloat, placeholder: LocalizedStringResource) {
        self._controller = controller
        self.minHeight = minHeight
        self.placeholder = placeholder
    }

    var body: some View {
        NoteUITextViewRepresentable(
            controller: controller,
            showKeyboard: true
        )
        .frame(maxWidth: .infinity)
        .frame(height: max(minHeight, controller.intrinsicHeight, 0))
        .padding(.leading, 6)
        .background { Color.appBg }
        .sheet(isPresented: $controller.showMentionsAutocomplete) {
            NavigationStack {
                AuthorListView(isPresented: $controller.showMentionsAutocomplete) { [weak controller] author in
                    /// Guard against double presses
                    guard let controller, controller.showMentionsAutocomplete else { return }

                    controller.insertMention(of: author)
                    controller.showMentionsAutocomplete = false
                }
            }
        }
    }
}

#Preview {

    var previewData = PreviewData()
    @State var controller = NoteEditorController()
    let placeholder: LocalizedStringResource = .localizable.newNotePlaceholder

    return NavigationStack {
        NoteTextEditor(
            controller: $controller,
            minHeight: 500,
            placeholder: placeholder
        )
        Spacer()
    }
    .inject(previewData: previewData)
    .onAppear {
        _ = previewData.alice
    }
}
