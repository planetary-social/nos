import SwiftUI

/// Displays a reply note below its root note.
struct ThreadRootView<Reply: View>: View {

    /// The root note.
    let root: Event

    /// Whether the root note is interactive.
    let isRootNoteInteractive: Bool

    /// Handler to be executed when the user taps on the root note.
    let tapAction: ((Event) -> Void)?

    /// Handler to be executed when building a View for displaying the reply note.
    let reply: Reply

    /// Initializes a Thread Root View.
    /// - Parameters:
    ///   - root: The root note.
    ///   - isRootNoteInteractive: Whether the root note is interactive. Defaults to `true`.
    ///   - tapAction: Handler to be executed when the user taps on the root note.
    ///   - reply: Handler to be executed when building a View for displaying the reply note.
    init(
        root: Event,
        isRootNoteInteractive: Bool = true,
        tapAction: ((Event) -> Void)?,
        @ViewBuilder reply: () -> Reply
    ) {
        self.root = root
        self.isRootNoteInteractive = isRootNoteInteractive
        self.tapAction = tapAction
        self.reply = reply()
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            NoteButton(
                note: root,
                shouldTruncate: true,
                hideOutOfNetwork: false,
                tapAction: tapAction
            )
            .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
            .readabilityPadding()
            .allowsHitTesting(isRootNoteInteractive)
            .opacity(0.7)
            .frame(height: 100, alignment: .top)
            .clipped()

            reply
                .offset(y: 100)
                .padding(
                    EdgeInsets(top: 0, leading: 0, bottom: 100, trailing: 0)
                )
        }
    }
}

struct ThreadRootView_Previews: PreviewProvider {
    static var previewData = PreviewData()
    
    static var previews: some View {
        ScrollView {
            VStack {
                ThreadRootView(
                    root: previewData.longNote, 
                    tapAction: { _ in },
                    reply: {
                        NoteButton(
                            note: previewData.reply,
                            hideOutOfNetwork: false
                        )
                    }
                )
            }
        }
        .background(Color.appBg)
        .inject(previewData: previewData)
    }
}
