//
//  OnboardingView.swift
//  Nos
//
//  Created by Shane Bielefeld on 2/14/23.
//

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
    case ageVerification
    case notOldEnough
    case termsOfService
    case finishOnboarding
}

struct OnboardingView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @ObservedObject var state = OnboardingState()
    
    /// Completion to be called when all onboarding steps are complete
    let completion: () -> Void
    
    @State private var selectedTab: OnboardingStep = .onboardingStart
    
    @State private var keyPair: KeyPair? {
        didSet {
            if let pair = keyPair {
                let privateKey = Data(pair.privateKeyHex.utf8)
                let publicStatus = KeyChain.save(key: KeyChain.keychainPrivateKey, data: privateKey)
                print("Public key keychain storage status: \(publicStatus)")
            }
        }
    }
    
    @State var flow: OnboardingFlow = .createAccount
    
    @Dependency(\.analytics) private var analytics
    
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
                    case .termsOfService:
                        OnboardingTermsOfServiceView()
                            .environmentObject(state)
                    case .finishOnboarding:
                        switch state.flow {
                        case .createAccount:
                            // hack to allow us to do business logic here... we won't need this once
                            // we have a dedicated CreateAccountView that handles setting up the current user
                            // swiftlint: disable redundant_discardable_let
                            let _ = {
                            // swiftlint: enable redundant_discardable_let
                                let keyPair = KeyPair()!
                                self.keyPair = keyPair
                                analytics.identify(with: keyPair)
                                analytics.generatedKey()
                                
                                // Recommended Relays for new user
                                for address in Relay.recommended {
                                    _ = try? Relay(
                                        context: viewContext,
                                        address: address,
                                        author: CurrentUser.shared.author
                                    )
                                }
                                try? CurrentUser.shared.context.save()
                                
                                CurrentUser.shared.publishContactList(tags: [])
                            }()
                            ProfileEditView(author: CurrentUser.shared.author!, createAccountCompletion: completion)
                        case .loginToExistingAccount:
                            OnboardingLoginView(completion: completion)
                        }
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
