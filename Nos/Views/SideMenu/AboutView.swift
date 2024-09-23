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
                Text(.localizable.onboardingTitle)
                    .font(.custom("ClarityCity-Bold", size: 25.21))
                    .fontWeight(.heavy)
                    .foregroundStyle(LinearGradient.diagonalAccent2.blendMode(.normal))
                
                VStack {
                    HighlightedText(
                        String(localized: .localizable.aboutNos),
                        highlightedWord: String(localized: .localizable.aboutNosHighlight),
                        highlight: .diagonalAccent,
                        link: URL(string: "https://nos.social")
                    )
                    .padding(.vertical, 10)
                    HighlightedText(
                        String(localized: .localizable.aboutNostr),
                        highlightedWord: String(localized: .localizable.aboutNostrHighlight),
                        highlight: .diagonalAccent,
                        link: URL(string: "https://nostr.how")
                    )
                    .padding(.vertical, 10)
                    HighlightedText(
                        String(localized: .localizable.nosIsOpenSource),
                        highlightedWord: String(localized: .localizable.nosIsOpenSourceHighlight),
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
        .nosNavigationBar(title: .localizable.about)
        .background(Color.appBg)
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
