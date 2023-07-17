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
    var completion: () -> Void
    
    @Dependency(\.analytics) private var analytics
    @EnvironmentObject var currentUser: CurrentUser
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @State var privateKeyString = ""
    @State var showError = false
    
    func importKey(_ keyPair: KeyPair) async {
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
                    SecureField(Localized.privateKeyPlaceholder.string, text: $privateKeyString)
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
        .nosNavigationBar(title: Localized.login)
        .alert(isPresented: $showError) {
            Alert(
                title: Localized.invalidKey.view,
                message: Localized.couldNotReadPrivateKeyMessage.view
            )
        }
    }
}
