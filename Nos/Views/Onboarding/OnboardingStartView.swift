import SwiftUI
import Dependencies

struct OnboardingStartView: View {
    @EnvironmentObject var state: OnboardingState
    @Dependency(\.analytics) private var analytics
    
    var body: some View {
        VStack {
            Text("Stay Real")
            Text(.localizable.onboardingTitle)
                .font(.custom("ClarityCity-Bold", size: 25.21))
                .fontWeight(.heavy)
                .foregroundStyle(LinearGradient.diagonalAccent2.blendMode(.normal))
            Spacer()
            BigActionButton(title: .localizable.tryIt) {
                state.flow = .createAccount
                state.step = .termsOfService
            }
            .padding(.horizontal, 24)
            .padding(.bottom)
            Button(String(localized: .localizable.loginWithKey)) {
                state.flow = .loginToExistingAccount
                state.step = .termsOfService
            }
            .padding(.bottom, 50)
        }
        .background(Color.appBg)
        .navigationBarHidden(true)
        .onAppear {
            analytics.startedOnboarding()
        }
    }
}
