//
//  OnboardingLoginView.swift
//  Nos
//
//  Created by Shane Bielefeld on 3/16/23.
//

import SwiftUI
import Dependencies
import Logger

struct OnboardingLoginView: View {
    let completion: @MainActor () -> Void
    
    @Dependency(\.analytics) private var analytics
    @Environment(CurrentUser.self) var currentUser
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @State var privateKeyString = ""
    @State var showError = false
    
    @MainActor func importKey(_ keyPair: KeyPair) async {
        await currentUser.setKeyPair(keyPair)
        analytics.importedKey()

        for address in Relay.allKnown {
            do {
                let relay = try Relay(
                    context: viewContext,
                    address: address,
                    author: currentUser.author
                )
                currentUser.onboardingRelays.append(relay)
            } catch {
                Log.error(error.localizedDescription)
            }
        }
        try? currentUser.viewContext.saveIfNeeded()

        completion()
    }
    
    var body: some View {
        VStack {
            Form {
                Section {
                    SecureField(String(localized: .localizable.privateKeyPlaceholder), text: $privateKeyString)
                        .foregroundColor(.primaryTxt)
                } header: {
                    Text(.localizable.pasteYourSecretKey)
                        .foregroundColor(.primaryTxt)
                        .fontWeight(.heavy)
                }
                .listRowBackground(LinearGradient(
                    colors: [Color.cardBgTop, Color.cardBgBottom],
                    startPoint: .top,
                    endPoint: .bottom
                ))
            }
            if !privateKeyString.isEmpty {
                BigActionButton(title: .localizable.login) {
                    if let keyPair = KeyPair(nsec: privateKeyString) {
                        await importKey(keyPair)
                    } else if let keyPair = KeyPair(privateKeyHex: privateKeyString) {
                        await importKey(keyPair)
                    } else {
                        self.showError = true
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBg)
        .nosNavigationBar(title: .localizable.login)
        .alert(isPresented: $showError) {
            Alert(
                title: Text(.localizable.invalidKey),
                message: Text(.localizable.couldNotReadPrivateKeyMessage)
            )
        }
    }
}
