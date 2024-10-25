import Dependencies
import SwiftUI

struct OnboardingTermsOfServiceView: View {
    @EnvironmentObject var state: OnboardingState
    @Environment(CurrentUser.self) var currentUser

    @Dependency(\.crashReporting) private var crashReporting
    
    /// Completion to be called when all onboarding steps are complete
    let completion: @MainActor () -> Void
    
    var body: some View {
        VStack {
            Text(.localizable.termsOfServiceTitle)
                .font(.clarity(.bold, textStyle: .largeTitle))
                .foregroundStyle(LinearGradient.diagonalAccent2.blendMode(.normal))
                .padding(.top, 92)
                .padding(.bottom, 60)
            ScrollView {
                Text(termsOfService)
                    .font(.clarity(.regular))
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
                BigActionButton(title: .localizable.reject) {
                    state.step = .onboardingStart
                }
                Spacer(minLength: 15)
                BigActionButton(title: .localizable.accept) {
                    switch state.flow {
                    case .createAccount:
                        do {
                            try await currentUser.createAccount()
                            completion()
                        } catch {
                            crashReporting.report(error)
                        }
                    case .loginToExistingAccount:
                        state.step = .login
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

// We don't localize these for legal reasons
fileprivate let termsOfService = """
    Legal stuff blah blah blah
"""
