//
//  OnboardingTermsOfServiceView.swift
//  Nos
//
//  Created by Shane Bielefeld on 3/16/23.
//

import SwiftUI

struct OnboardingTermsOfServiceView: View {
    @EnvironmentObject var state: OnboardingState
    
    var body: some View {
        VStack {
            PlainText(Localized.termsOfServiceTitle.string)
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
                .padding(.top, 92)
                .padding(.bottom, 60)
            ScrollView {
                Text(Localized.termsOfService.string)
                    .foregroundColor(.secondaryTxt)
                Rectangle().fill(Color.clear)
                    .frame(height: 100)
            }
            .mask(
                VStack(spacing: 0) {
                    Rectangle().fill(Color.black)
                    LinearGradient(
                        colors: [Color.black, Color.black.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            )
            .padding(.horizontal, 44.5)
            HStack {
                BigActionButton(title: Localized.reject) {
                    state.step = .onboardingStart
                }
                Spacer(minLength: 15)
                BigActionButton(title: Localized.accept) {
                    state.step = .finishOnboarding
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 50)
        }
        .background(Color.appBg)
        .navigationBarHidden(true)
    }
}
