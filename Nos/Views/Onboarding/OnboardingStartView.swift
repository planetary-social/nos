import SwiftUI
import Dependencies

struct OnboardingStartView: View {
    @EnvironmentObject var state: OnboardingState
    @Dependency(\.analytics) private var analytics
    
    var body: some View {
        VStack {
            Image.nosLogo
                .resizable()
                .frame(width: 235.45, height: 67.1)
                .padding(.top, 155)
                .padding(.bottom, 10)
            Text("onboardingTitle")
                .font(.custom("ClarityCity-Bold", size: 25.21))
                .fontWeight(.heavy)
                .foregroundStyle(LinearGradient.diagonalAccent2.blendMode(.normal))
            Spacer()
            BigActionButton("tryIt") {
                state.flow = .createAccount
                state.step = .ageVerification
            }
            .padding(.horizontal, 24)
            .padding(.bottom)
            Button("loginWithKey") {
                state.flow = .loginToExistingAccount
                state.step = .ageVerification
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
