import SwiftUI

struct ReplyButton: View {
    let note: Event
    let replyAction: ((Event) -> Void)?

    @EnvironmentObject private var router: Router
    
    var body: some View {
        Button(action: {
            if let replyAction {
                replyAction(note)
            } else {
                router.push(.replyTo(note.identifier))
            }
        }, label: {
            Image.buttonReply
                .padding(.leading, 10)
                .padding(.trailing, 23)
                .padding(.vertical, 12)
        })
    }
}
