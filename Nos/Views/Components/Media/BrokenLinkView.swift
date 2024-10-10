import SwiftUI

/// A view that shows a broken link icon to inform the user that the link is broken. The user can tap the view to open
/// the link in the browser.
struct BrokenLinkView: View {
    /// The URL of the broken link
    let url: URL

    @Environment(\.openURL) private var openURL

    var body: some View {
        Button {
            openURL(url)
        } label: {
            ZStack {
                LinearGradient.brokenLinkBackground
                Image.brokenLink
                    .scaledToFit()
                    .frame(width: 124, height: 124)
                    .foregroundStyle(Color.brokenLink)
                    .padding()
            }
        }
    }
}

#Preview {
    ZStack {
        LinearGradient.cardBackground
        AspectRatioContainer(orientation: .portrait) {
            BrokenLinkView(url: URL(string: "https://example.com/no.jpg")!)
        }
    }
}
