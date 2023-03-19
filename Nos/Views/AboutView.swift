//
//  AboutView.swift
//  Nos
//
//  Created by Matthew Lorentz on 3/18/23.
//

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
                PlainText(Localized.onboardingTitle.string)
                    .font(.custom("ClarityCity-Bold", size: 25.21))
                    .fontWeight(.heavy)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(hex: "#F08508"),
                                Color(hex: "#F43F75")
                            ],
                            startPoint: .bottomLeading,
                            endPoint: .topTrailing
                        )
                        .blendMode(.normal)
                    )
                
                VStack {
                    HighlightedText(
                        Localized.aboutNos.string,
                        highlightedWord: Localized.aboutNosHighlight.string,
                        highlight: .diagonalAccent,
                        link: URL(string: "https://nos.social")
                    )
                    .padding(.vertical, 10)
                    HighlightedText(
                        Localized.aboutNostr.string,
                        highlightedWord: Localized.aboutNostrHighlight.string,
                        highlight: .diagonalAccent,
                        link: URL(string: "https://nostr.how")
                    )
                    .padding(.vertical, 10)
                    HighlightedText(
                        Localized.nosIsOpenSource.string,
                        highlightedWord: Localized.nosIsOpenSourceHighlight.string,
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
        .nosNavigationBar(title: .about)
        .background(Color.appBg)
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AboutView()
        }
    }
}
