import SwiftUI

struct ThreadRootView<Reply: View>: View {
    var root: Event
    var tapAction: ((Event) -> Void)?
    var reply: Reply

    init(root: Event, tapAction: ((Event) -> Void)?, @ViewBuilder reply: () -> Reply) {
        self.root = root
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
