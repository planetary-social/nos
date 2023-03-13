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
        case getStarted
        case addPrivateKey
    }
    
    /// Completion to be called when all onboarding steps are complete
    let completion: () -> Void
    
    @State private var selectedTab: OnboardingStep = .getStarted
    
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
            VStack {
                Spacer()
                Localized.Onboarding.getStartedTitle.view
                Spacer()
                Button(Localized.Onboarding.getStartedButton.string) {
                    selectedTab = .addPrivateKey
                }
                .buttonStyle(.bordered)
                Spacer()
            }
            .tag(OnboardingStep.getStarted)
            .onViewDidLoad {
                analytics.startedOnboarding()
            }
            
            NavigationStack {
                VStack {
                    Spacer()
                    Localized.Onboarding.privateKeyTitle.view
                    Spacer()
                    Button(Localized.Onboarding.generatePrivateKeyButton.string) {
                        let keyPair = KeyPair()!
                        self.keyPair = keyPair
                        analytics.identify(with: keyPair)
                        analytics.generatedKey()

                        // Recommended Relays for new user
                        for address in Relay.recommended {
                            Relay(context: viewContext, address: address, author: CurrentUser.shared.author)
                        }

                        CurrentUser.shared.publishContactList(tags: [])
                        
                        completion()
                    }
                    .buttonStyle(.bordered)
                    NavigationLink(Localized.Onboarding.alreadyHaveAPrivateKey.string) {
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
                                    
                                    // Use these to sync
                                    for address in Relay.allKnown {
                                        let relay = Relay(context: viewContext, address: address, author: nil)
                                        CurrentUser.shared.onboardingRelays.append(relay)
                                    }

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
                    .font(.system(size: 10))
                    Spacer()
                }
            }
            .tag(OnboardingStep.addPrivateKey)
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView {}
    }
}
