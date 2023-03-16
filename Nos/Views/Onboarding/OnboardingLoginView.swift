//
//  OnboardingLoginView.swift
//  Nos
//
//  Created by Shane Bielefeld on 3/16/23.
//

import SwiftUI
import Dependencies

struct OnboardingLoginView: View {
    var completion: () -> Void
    
    @Dependency(\.analytics) private var analytics
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @State var privateKeyString = ""
    @State var showError = false
    
    var body: some View {
        VStack {
            Form {
                Section {
                    TextField("NSec1", text: $privateKeyString)
                        .foregroundColor(.textColor)
                } header: {
                    Localized.pasteYourSecretKey.view
                        .foregroundColor(.textColor)
                        .fontWeight(.heavy)
                }
                .listRowBackground(LinearGradient(
                    colors: [Color.cardBgTop, Color.cardBgBottom],
                    startPoint: .top,
                    endPoint: .bottom
                ))
            }
            if !privateKeyString.isEmpty {
                BigActionButton(title: .login) {
                    if let keyPair = KeyPair(nsec: privateKeyString) {
                        let privateKey = Data(keyPair.privateKeyHex.utf8)
                        let publicStatus = KeyChain.save(key: KeyChain.keychainPrivateKey, data: privateKey)
                        print("Public key keychain storage status: \(publicStatus)")
                        analytics.identify(with: keyPair)
                        analytics.importedKey()

                        // Use these to sync
                        for address in Relay.allKnown {
                            let relay = Relay(context: viewContext, address: address, author: nil)
                            CurrentUser.shared.onboardingRelays.append(relay)
                        }

                        completion()
                    } else {
                        self.showError = true
                    }
                }
                .padding(.horizontal, 24)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBg)
        .navigationTitle(Localized.loginToYourAccount.string)
        .alert(isPresented: $showError) {
            Alert(
                title: Localized.invalidKey.view,
                message: Localized.couldNotReadPrivateKeyMessage.view
            )
        }
    }
}
