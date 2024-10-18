import SwiftUI

/// The state of onboarding, tracking the flow, steps, and success or failure of a few specific tasks.
@Observable final class OnboardingState {
    var flow: OnboardingFlow = .createAccount
    var step: OnboardingStep = .onboardingStart {
        didSet {
            path.append(step)
        }
    }
    var path = NavigationPath()
    
    /// Whether the user succeeded in setting their display name
    var displayNameSucceeded = false

    /// Whether the user succeeded in setting their username
    var usernameSucceeded = false
    
    /// Whether the user succeeded in all steps of onboarding
    var allStepsSucceeded: Bool {
        displayNameSucceeded && usernameSucceeded
    }
}

enum OnboardingFlow {
    case createAccount
    case loginToExistingAccount
}

enum OnboardingStep {
    case onboardingStart
    case ageVerification
    case notOldEnough
    case createAccount
    case privateKey
    case publicKey
    case displayName
    case username
    case accountSuccess
    case buildYourNetwork
    case login
}

/// The view that initializes the onboarding navigation stack and shows the first view.
struct OnboardingView: View {
    @State var state = OnboardingState()
    
    /// Completion to be called when all onboarding steps are complete
    let completion: @MainActor () -> Void
    
    var body: some View {
        NavigationStack(path: $state.path) {
            OnboardingStartView()
                .environment(state)
                .navigationDestination(for: OnboardingStep.self) { step in
                    switch step {
                    case .onboardingStart:
                        OnboardingStartView()
                            .environment(state)
                    case .ageVerification:
                        OnboardingAgeVerificationView()
                            .environment(state)
                    case .notOldEnough:
                        OnboardingNotOldEnoughView()
                            .environment(state)
                    case .createAccount:
                        CreateAccountView()
                            .environment(state)
                    case .privateKey:
                        PrivateKeyView()
                            .environment(state)
                    case .publicKey:
                        PublicKeyView()
                            .environment(state)
                    case .displayName:
                        DisplayNameView()
                            .environment(state)
                    case .username:
                        UsernameView()
                            .environment(state)
                    case .accountSuccess:
                        AccountSuccessView()
                            .environment(state)
                    case .login:
                        OnboardingLoginView(completion: completion)
                    case .buildYourNetwork:
                        BuildYourNetworkView(completion: completion)
                    }
                }
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView {}
            .inject(previewData: PreviewData())
    }
}
