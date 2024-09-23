import SwiftUI

struct OnboardingNotOldEnoughView: View {
    @EnvironmentObject var state: OnboardingState
    
    var body: some View {
        VStack {
            Text(.localizable.notOldEnoughTitle)
                .font(.custom("ClarityCity-Bold", size: 34, relativeTo: .largeTitle))
                .foregroundStyle(LinearGradient.diagonalAccent2.blendMode(.normal))
                .multilineTextAlignment(.center)
                .padding(.top, 92)
                .padding(.bottom, 20)
                .padding(.horizontal, 45)
            Text(.localizable.notOldEnoughSubtitle)
                .foregroundColor(.secondaryTxt)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 45)
            Spacer()
            BigActionButton(title: .localizable.notOldEnoughButton) {
                state.step = .onboardingStart
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 50)
        }
        .background(Color.appBg)
        .navigationBarHidden(true)
    }
}
