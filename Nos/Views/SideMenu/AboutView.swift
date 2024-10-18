import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack {
                Spacer()
                Image.nosLogo
                    .resizable()
                    .frame(width: 235.45, height: 67.1)
                    .padding(.top, 155)
                    .padding(.bottom, 10)
                Text("onboardingTitle")
                    .font(.custom("ClarityCity-Bold", size: 25.21))
                    .fontWeight(.heavy)
                    .foregroundStyle(LinearGradient.diagonalAccent2.blendMode(.normal))
                
                VStack {
                    HighlightedText(
                        String(localized: "aboutNos"),
                        highlightedWord: String(localized: "aboutNosHighlight"),
                        highlight: .diagonalAccent,
                        link: URL(string: "https://nos.social")
                    )
                    .padding(.vertical, 10)
                    HighlightedText(
                        String(localized: "aboutNostr"),
                        highlightedWord: String(localized: "aboutNostrHighlight"),
                        highlight: .diagonalAccent,
                        link: URL(string: "https://nostr.how")
                    )
                    .padding(.vertical, 10)
                    HighlightedText(
                        String(localized: "nosIsOpenSource"),
                        highlightedWord: String(localized: "nosIsOpenSourceHighlight"),
                        highlight: .diagonalAccent,
                        link: URL(string: "https://github.com/planetary-social/nos")
                    )
                    .padding(.vertical, 10)
                }
                .frame(maxWidth: 400)
                .padding(.horizontal, 20)

                Spacer()
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
        }
        .nosNavigationBar("about")
        .background(Color.appBg)
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
