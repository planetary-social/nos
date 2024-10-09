import SwiftUI
import Logger

/// A view similar to `TextEditor` for composing Nostr notes. Supports autocomplete of mentions.
struct NoteTextEditor: View {
    
    /// A controller for the entered text.
    @Binding private var controller: NoteEditorController
    
    /// The smallest size of EditableNoteText
    var minHeight: CGFloat
    
    var placeholder: LocalizedStringResource

    /// The authors who replied under the note the user is replying if any.
    var threadAuthors: [Author]?

    init(
        controller: Binding<NoteEditorController>,
        minHeight: CGFloat,
        placeholder: LocalizedStringResource,
        threadAuthors: [Author]? = nil
    ) {
        self._controller = controller
        self.minHeight = minHeight
        self.placeholder = placeholder
        self.threadAuthors = threadAuthors
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
                    threadAuthors: threadAuthors
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
    let placeholder: LocalizedStringResource = .localizable.newNotePlaceholder
    
    return NavigationStack {
        NoteTextEditor(
            controller: $controller,
            minHeight: 500,
            placeholder: placeholder,
            threadAuthors: []
        )
        Spacer()
    }
    .inject(previewData: previewData)
    .onAppear { 
        _ = previewData.alice
    }
}
