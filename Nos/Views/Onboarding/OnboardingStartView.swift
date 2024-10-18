import Dependencies
import SwiftUI

/// The beginning of the Onboarding views which contains buttons to start creating a new account or log in.
struct OnboardingStartView: View {
    @Environment(OnboardingState.self) private var state

    @Dependency(\.analytics) private var analytics

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 30) {
                Image.nosLogo
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200)
                    .padding(.bottom, 40)

                Image.network
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: geometry.size.width)
                Spacer()

                Group {
                    BigActionButton("newToNostr") {
                        state.flow = .createAccount
                        state.step = .ageVerification
                    }

                    Button("logInWithAccount") {
                        state.flow = .loginToExistingAccount
                        state.step = .ageVerification
                    }
                    .foregroundStyle(Color.primaryTxt)

                    Text("acceptTermsAndPrivacy")
                        .foregroundStyle(Color.secondaryTxt)
                        .font(.footnote)
                        .tint(Color.primaryTxt)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 40)
            }
            .padding(.vertical, 40)
            .background(Color.appBg)
            .navigationBarHidden(true)
        }
        .onAppear {
            analytics.startedOnboarding()
        }
    }
}

#Preview {
    OnboardingStartView()
        .environment(OnboardingState())
        .inject(previewData: PreviewData())
}
