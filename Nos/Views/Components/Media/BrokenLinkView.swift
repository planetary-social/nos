import SwiftUI

/// A view that shows a broken link icon to inform the user that the link is broken.
struct BrokenLinkView: View {
    var body: some View {
        ZStack {
            Color.brokenLinkBgOverlay
                .blendMode(.softLight)
            Image.brokenLink
                .scaledToFit()
                .frame(width: 124, height: 124)
                .foregroundStyle(Color.brokenLink)
                .padding()
        }
        .border(Color.profileDivider)
    }
}

#Preview {
    ZStack {
        LinearGradient.cardBackground
        AspectRatioContainer(orientation: .portrait) {
            BrokenLinkView()
        }
    }
}
