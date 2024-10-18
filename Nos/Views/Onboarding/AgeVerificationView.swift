import SwiftUI

/// The Age Verification view in the onboarding.
struct AgeVerificationView: View {
    @Environment(OnboardingState.self) private var state

    var body: some View {
        ZStack {
            Color.appBg
                .ignoresSafeArea()
            ViewThatFits(in: .vertical) {
                ageVerificationStack

                ScrollView {
                    ageVerificationStack
                }
            }
        }
        .navigationBarHidden(true)
    }

    var ageVerificationStack: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("🪪")
                .font(.system(size: 60))
            Text("ageVerificationHeadline")
                .font(.clarityBold(.title))
                .foregroundStyle(Color.primaryTxt)
                .fixedSize(horizontal: false, vertical: true)
            Text("ageVerificationDescription")
                .foregroundStyle(Color.secondaryTxt)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            HStack {
                BigActionButton("no") {
                    state.step = .notOldEnough
                }
                Spacer(minLength: 16)
                BigActionButton("yes") { @MainActor in
                    if state.flow == .loginToExistingAccount {
                        state.step = .login
                    } else {
                        state.step = .createAccount
                    }
                }
            }
        }
        .padding(40)
        .readabilityPadding()
    }
}

#Preview {
    AgeVerificationView()
        .environment(OnboardingState())
}
