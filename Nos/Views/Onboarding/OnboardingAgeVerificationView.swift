//
//  OnboardingAgeVerificationView.swift
//  Nos
//
//  Created by Shane Bielefeld on 3/15/23.
//

import SwiftUI

struct OnboardingAgeVerificationView: View {
    @EnvironmentObject var state: OnboardingState
    
    var body: some View {
        VStack {
            PlainText(.localizable.ageVerificationTitle)
                .multilineTextAlignment(.center)
                .padding(.top, 92)
                .padding(.bottom, 20)
                .padding(.horizontal, 77.5)
                .font(.custom("ClarityCity-Bold", size: 34, relativeTo: .largeTitle))
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
            Text(.localizable.ageVerificationSubtitle)
                .foregroundColor(.secondaryTxt)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 44.5)
            Spacer()
            HStack {
                BigActionButton(title: .localizable.no) {
                    state.step = .notOldEnough
                }
                Spacer(minLength: 15)
                BigActionButton(title: .localizable.yes) {
                    state.step = .termsOfService
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 50)
        }
        .background(Color.appBg)
        .navigationBarHidden(true)
    }
}
