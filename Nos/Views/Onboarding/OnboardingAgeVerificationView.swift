import Dependencies
import SwiftUI

/// The Age Verification view in the onboarding.
struct OnboardingAgeVerificationView: View {
    @EnvironmentObject var state: OnboardingState

    @Dependency(\.crashReporting) private var crashReporting
    @Dependency(\.currentUser) private var currentUser

    var body: some View {
        VStack {
            Text("ageVerificationTitle")
                .multilineTextAlignment(.center)
                .padding(.top, 92)
                .padding(.bottom, 20)
                .padding(.horizontal, 77.5)
                .font(.custom("ClarityCity-Bold", size: 34, relativeTo: .largeTitle))
                .foregroundStyle(LinearGradient.diagonalAccent2.blendMode(.normal))
            Text("ageVerificationSubtitle")
                .foregroundColor(.secondaryTxt)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 44.5)
            Spacer()
            HStack {
                BigActionButton("no") {
                    state.step = .notOldEnough
                }
                Spacer(minLength: 15)
                BigActionButton("yes") {
                    if state.flow == .loginToExistingAccount {
                        state.step = .login
                    } else {
                        // temporary; this will eventually move to the Create Account screen
                        do {
                            try await currentUser.createAccount()
                        } catch {
                            crashReporting.report(error)
                        }
                        // end temporary account creation

                        state.step = .buildYourNetwork
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 50)
        }
        .background(Color.appBg)
        .navigationBarHidden(true)
    }
}
