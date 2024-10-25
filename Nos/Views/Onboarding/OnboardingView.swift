import SwiftUI
import Dependencies
import Logger

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
    case termsOfService
    case login
}

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
                    case .termsOfService:
                        OnboardingTermsOfServiceView(completion: completion)
                            .environmentObject(state)
                    case .login:
                        OnboardingLoginView(completion: completion)
                    }
                }
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView {}
    }
}
