import SwiftUI

class OnboardingState: ObservableObject {
    @Published var flow: OnboardingFlow = .createAccount
    @Published var step: OnboardingStep = .onboardingStart {
        didSet {
            path.append(step)
        }
    }
    @Published var path = NavigationPath()
}

enum OnboardingFlow {
    case createAccount
    case loginToExistingAccount
}

enum OnboardingStep {
    case onboardingStart
    case ageVerification
    case notOldEnough
    case buildYourNetwork
    case login
}

/// The view that initializes the onboarding navigation stack and shows the first view.
struct OnboardingView: View {
    @StateObject var state = OnboardingState()
    
    /// Completion to be called when all onboarding steps are complete
    let completion: @MainActor () -> Void
    
    var body: some View {
        NavigationStack(path: $state.path) {
            OnboardingStartView()
                .environmentObject(state)
                .navigationDestination(for: OnboardingStep.self) { step in
                    switch step {
                    case .onboardingStart:
                        OnboardingStartView()
                            .environmentObject(state)
                    case .ageVerification:
                        OnboardingAgeVerificationView()
                            .environmentObject(state)
                    case .notOldEnough:
                        OnboardingNotOldEnoughView()
                            .environmentObject(state)
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
