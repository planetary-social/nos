//
//  OnboardingView.swift
//  Nos
//
//  Created by Shane Bielefeld on 2/14/23.
//

import SwiftUI

struct OnboardingView: View {
    enum OnboardingStep {
        case getStarted
        case generatePrivateKey
        case enterPrivateKey
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
    
    var body: some View {
        TabView(selection: $selectedTab) {
            VStack {
                Spacer()
                Text("Welcome to Nos")
                Spacer()
                Button("Let's get started") {
                    selectedTab = .generatePrivateKey
                }
                .buttonStyle(.bordered)
                Spacer()
            }
            .tag(OnboardingStep.getStarted)
            
            VStack {
                Spacer()
                Text("Private Key")
                Spacer()
                Button("Generate Private Key") {
                    let keyPair = KeyPair()!
                    self.keyPair = keyPair
                    
                    completion()
                }
                .buttonStyle(.bordered)
                Button("Already have a private key?") {
                    selectedTab = .enterPrivateKey
                }
                .font(.system(size: 10))
                Spacer()
            }
            .tag(OnboardingStep.generatePrivateKey)
            
            VStack {
                Spacer()
                Text("Add Private Key")
                Spacer()
                HStack {
                    Text("Private Key:")
                    TextField("Enter private key", text: $privateKeyString)
                        .padding()
                }
                .padding(50)
                Button("Save") {
                    if let keyPair = KeyPair(privateKeyHex: privateKeyString) {
                        self.keyPair = keyPair
                    } else {
                        self.keyPair = nil
                        self.showError = true
                    }
                    
                    completion()
                }
                .buttonStyle(.bordered)
                Spacer()
            }
            .tag(OnboardingStep.enterPrivateKey)
            .alert(isPresented: $showError) {
                Alert(
                    title: Localized.invalidKey.view,
                    message: Localized.couldNotReadPrivateKeyMessage.view
                )
            }
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView {}
    }
}
