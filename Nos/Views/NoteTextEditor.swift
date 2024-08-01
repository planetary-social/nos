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
        NoteTextViewRepresentable(
            controller: controller,
            showKeyboard: true
        )
        .frame(maxWidth: .infinity)
        .frame(height: max(minHeight, controller.intrinsicHeight, 0))
        .padding(.leading, 6)
        .background { Color.appBg }
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

#Preview {
    
    var previewData = PreviewData()
    @State var controller = NoteEditorController()
    let placeholder: LocalizedStringResource = .localizable.newNotePlaceholder
    
    return NavigationStack {
        NoteTextEditor(
            controller: $controller,
            initialContents: "", 
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
