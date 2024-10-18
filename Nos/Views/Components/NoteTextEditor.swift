import SwiftUI
import Logger

/// A view similar to `TextEditor` for composing Nostr notes. Supports autocomplete of mentions.
struct NoteTextEditor: View {

    /// A controller for the entered text.
    @Binding private var controller: NoteEditorController

    /// The smallest size of EditableNoteText
    var minHeight: CGFloat

    /// The authors who are referenced in a note in addition to those who replied to the note, if any.
    var relatedAuthors: [Author]

    init(
        controller: Binding<NoteEditorController>,
        minHeight: CGFloat,
        relatedAuthors: [Author] = []
    ) {
        self._controller = controller
        self.minHeight = minHeight
        self.relatedAuthors = relatedAuthors
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
                AuthorListView(
                    isPresented: $controller.showMentionsAutocomplete,
                    relatedAuthors: relatedAuthors
                ) { [weak controller] author in
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

    return NavigationStack {
        NoteTextEditor(
            controller: $controller,
            minHeight: 500,
            relatedAuthors: []
        )
        Spacer()
    }
    .inject(previewData: previewData)
    .onAppear {
        _ = previewData.alice
    }
}
