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
                if let verifiedNip05Identifier {
                    nip05Text(parts: nip05Parts)
                        .strikethrough(!verifiedNip05Identifier)
                } else {
                    nip05Text(parts: nip05Parts)
                        .foregroundStyle(Color.secondaryTxt)
                }
            }
            .lineLimit(1)
            .contextMenu {
                Button {
                    UIPasteboard.general.string = nip05Parts.username + "@" + nip05Parts.domain
                } label: {
                    Text(.localizable.copy)
                }
            } preview: {
                Text(nip05Parts.username + "@" + nip05Parts.domain)
                    .foregroundStyle(Color.primaryTxt)
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

    func nip05Text(parts: (username: String, domain: String)) -> some View {
        if parts.username == "_" {
            Text(parts.domain)
                .foregroundStyle(Color.primaryTxt)
        } else {
            Text(parts.username)
                .foregroundStyle(Color.primaryTxt) +
            Text("@" + parts.domain)
                .foregroundStyle(Color.secondaryTxt)
        }
    }
}
