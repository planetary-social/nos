//
//  OnboardingView.swift
//  Nos
//
//  Created by Shane Bielefeld on 2/14/23.
//

import SwiftUI
import Dependencies

struct OnboardingView: View {
    @Environment(\.managedObjectContext) private var viewContext

    enum OnboardingStep {
        case onboardingStart
        case addPrivateKey
        case ageVerification
        case notOldEnough
        case termsOfService
    }
    
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
    
    @State var privateKeyString = ""
    
    @State var showError = false
    
    @Dependency(\.analytics) private var analytics
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                VStack {
                    Image.nosLogo
                        .resizable()
                        .frame(width: 235.45, height: 67.1)
                        .padding(.top, 155)
                    Localized.onboardingTitle.view
                    Spacer()
                    BigActionButton(title: .createAccount) {
//                        let keyPair = KeyPair()!
//                        self.keyPair = keyPair
//                        analytics.identify(with: keyPair)
//                        analytics.generatedKey()
//
//                        // Default Relays for new user
//                        for address in Relay.defaults {
//                            Relay(context: viewContext, address: address, author: CurrentUser.author)
//                        }
//
//                        CurrentUser.publishContactList(tags: [], context: viewContext)
//
//                        completion()
                        selectedTab = .ageVerification
                    }
                    .padding()
                    NavigationLink(Localized.logInWithYourKeys.string) {
                        VStack {
                            Spacer()
                            Localized.Onboarding.addPrivateKeyTitle.view
                            Spacer()
                            HStack {
                                Localized.Onboarding.privateKeyPrompt.view
                                TextField(Localized.privateKeyPlaceholder.string, text: $privateKeyString)
                                    .padding()
                            }
                            .padding(50)
                            Button(Localized.save.string) {
                                if let keyPair = KeyPair(nsec: privateKeyString) {
                                    self.keyPair = keyPair
                                    analytics.identify(with: keyPair)
                                    analytics.importedKey()
                                    completion()
                                } else {
                                    self.keyPair = nil
                                    self.showError = true
                                }
                            }
                            .buttonStyle(.bordered)
                            Spacer()
                        }
                        .alert(isPresented: $showError) {
                            Alert(
                                title: Localized.invalidKey.view,
                                message: Localized.couldNotReadPrivateKeyMessage.view
                            )
                        }
                    }
                    .padding()
                }
            }
            .tag(OnboardingStep.onboardingStart)
            
            // Age verification
            VStack {
                Text(Localized.ageVerificationTitle.string)
                    .padding(.top, 92)
                Text(Localized.ageVerificationSubtitle.string)
                Spacer()
                HStack {
                    BigActionButton(title: .no) {
                        selectedTab = .notOldEnough
                    }
                    BigActionButton(title: .yes) {
                        selectedTab = .termsOfService
                    }
                }
                .padding(.horizontal)
            }
            .tag(OnboardingStep.ageVerification)
            
            // Not old enough
            VStack {
                Text(Localized.notOldEnoughTitle.string)
                    .padding(.top, 92)
                Text(Localized.notOldEnoughSubtitle.string)
                Spacer()
                BigActionButton(title: .notOldEnoughButton) {
                    selectedTab = .onboardingStart
                }
            }
            .tag(OnboardingStep.notOldEnough)
            
            // Terms of Service
            VStack {
                Text(Localized.termsOfServiceTitle.string)
                    .padding(.top, 92)
                ScrollView {
                    Text(Localized.termsOfService.string)
                }
                .padding(.horizontal, 44.5)
                HStack {
                    BigActionButton(title: Localized.reject) {
                        selectedTab = .onboardingStart
                    }
                    BigActionButton(title: Localized.accept) {
                        // TODO: create account
                    }
                }
                .padding(.horizontal)
            }
            .tag(OnboardingStep.termsOfService)
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView {}
    }
}
