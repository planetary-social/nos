import Dependencies
import Logger
import SwiftUI

/// Displays a user's NIP-05 if they have one and does some verification on it.
struct NIP05View: View {
    
    @ObservedObject var author: Author
    
    @State private var verifiedNip05Identifier: Bool?
    @Dependency(\.namesAPI) private var namesAPI

    var body: some View {
        if let nip05Identifier = author.nip05,
            !nip05Identifier.isEmpty,
            let nip05Parts = author.nip05Parts {
            Group {
                if verifiedNip05Identifier == true {
                    Text(nip05Parts.username)
                        .foregroundColor(.primaryTxt) +
                    Text(nip05Parts.atDomain)
                        .foregroundColor(.secondaryTxt)
                } else if verifiedNip05Identifier == false {
                    (
                        Text(nip05Parts.username)
                            .foregroundColor(.primaryTxt) +
                        Text(nip05Parts.atDomain)
                            .foregroundColor(.secondaryTxt)
                    )
                    .strikethrough()
                } else {
                    (
                        Text(nip05Parts.username) +
                        Text(nip05Parts.atDomain)
                    )
                    .foregroundColor(.secondaryTxt)
                }
            }
            .lineLimit(1)
            .contextMenu {
                Button {
                    UIPasteboard.general.string = nip05Parts.username + nip05Parts.atDomain
                } label: {
                    Text(.localizable.copy)
                }
            } preview: {
                Text(nip05Parts.username + nip05Parts.atDomain)
                    .foregroundColor(.primaryTxt)
                    .padding()
            }
            .task(priority: .userInitiated) {
                if let nip05Identifier = author.nip05, let publicKey = author.publicKey {

                    let isVerified: Bool
                    do {
                        isVerified = try await namesAPI.verify(
                            username: nip05Identifier,
                            publicKey: publicKey
                        )
                    } catch {
                        isVerified = false
                        Log.debug(error.localizedDescription)
                    }
                    withAnimation {
                        self.verifiedNip05Identifier = isVerified
                    }
                }
            }
        } else {
            EmptyView()
        }
    }
}
