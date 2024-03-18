import SwiftUI

/// Displays a user's NIP-05 and does some verification on it.
struct NIP05View: View {
    
    @ObservedObject var author: Author
    
    @State private var verifiedNip05Identifier: Bool?
    @EnvironmentObject private var relayService: RelayService
    
    var body: some View {
        if let nip05Identifier = author.nip05,
            !nip05Identifier.isEmpty,
            let formattedNIP05 = author.formattedNIP05 {
            Group {
                if verifiedNip05Identifier == true {
                    PlainText("\(formattedNIP05)")
                        .foregroundColor(.primaryTxt)
                } else if verifiedNip05Identifier == false {
                    PlainText(formattedNIP05)
                        .strikethrough()
                        .foregroundColor(.secondaryTxt)
                } else {
                    PlainText("\(formattedNIP05)")
                        .foregroundColor(.secondaryTxt)
                }
            }
            .font(.clarity(.medium, textStyle: .subheadline))
            .multilineTextAlignment(.leading)
            .contextMenu {
                Button {
                    UIPasteboard.general.string = formattedNIP05
                } label: {
                    Text(.localizable.copy)
                }
            } preview: {
                PlainText(formattedNIP05)
                    .foregroundColor(.primaryTxt)
                    .padding()
            }
            .task(priority: .userInitiated) {
                if let nip05Identifier = author.nip05,
                    let publicKey = author.publicKey?.hex {
                    let verifiedNip05Identifier = await relayService.verifyNIP05(
                        identifier: nip05Identifier,
                        userPublicKey: publicKey
                    )
                    withAnimation {
                        self.verifiedNip05Identifier = verifiedNip05Identifier
                    }
                }
            }
        } else {
            EmptyView()
        }
    }
}
