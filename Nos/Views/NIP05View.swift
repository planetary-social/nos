import Dependencies
import Logger
import SwiftUI

/// Displays a user's NIP-05 in multiple colors and does some verification on it.
struct NIP05View: View {
    @ObservedObject var author: Author

    @State private var verifiedNip05Identifier: Bool?
    @Dependency(\.namesAPI) private var namesAPI

    var body: some View {
        if let nip05 = author.nip05, !nip05.isEmpty {
            Group {
                if let nip05Parts = author.nip05Parts {
                    if let verifiedNip05Identifier {
                        nip05Text(parts: nip05Parts)
                            .strikethrough(!verifiedNip05Identifier)
                    } else {
                        nip05Text(parts: nip05Parts)
                    }
                } else {
                    invalidNip05Text(nip05: nip05)
                }
            }
            .contextMenu {
                Button {
                    UIPasteboard.general.string = nip05
                } label: {
                    Text(.localizable.copy)
                }
            } preview: {
                Text(nip05)
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
                    } catch URLError.cancelled {
                        // URLSession cancels the request when the task is
                        // cancelled. Cancelled requests are common specially in
                        // bad networks because it is normal that the user
                        // scrolls past the author before the requests
                        // completes. Thus, we need to catch .cancelled so we
                        // don't display a strike-through in those cases.
                        return
                    } catch {
                        isVerified = false
                        let message = error.localizedDescription
                        Log.debug("Error while verifying a NIP-05: \(message)")
                    }
                    self.verifiedNip05Identifier = isVerified
                }
            }
        } else {
            EmptyView()
        }
    }

    /// A view that displays the given parts of the NIP-05 in different colors.
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

    /// A view that displays the given `nip05` as text with strikethrough.
    /// Useful for when a user's NIP-05 is invalid, such as when they enter a raw domain like "example.com"
    /// for their NIP-05 identifier.
    func invalidNip05Text(nip05: String) -> some View {
        Text(nip05)
            .foregroundStyle(Color.primaryTxt)
            .strikethrough()
    }
}
