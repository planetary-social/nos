//
//  SettingsView.swift
//  Nos
//
//  Created by Matthew Lorentz on 2/3/23.
//

import SwiftUI
import Dependencies

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Dependency(\.analytics) private var analytics
    @EnvironmentObject private var appController: AppController
    @EnvironmentObject private var router: Router

    @State private var keyPair: KeyPair? {
        didSet {
            if let pair = keyPair {
                let privateKey = Data(pair.privateKeyHex.utf8)
                let publicStatus = KeyChain.save(key: KeyChain.keychainPrivateKey, data: privateKey)
                print("Private key keychain storage status: \(publicStatus)")
            } else {
                let publicStatus = KeyChain.delete(key: KeyChain.keychainPrivateKey)
                print("Private key keychain delete operation status: \(publicStatus)")
            }
        }
    }
    
    @State var privateKeyString = ""
    
    @State var showError = false
    
    var body: some View {
        Form {
            Section {
                Localized.keyEncryptionWarning.view
                    .foregroundColor(.primaryTxt)
                HStack {
                    TextField(Localized.privateKeyPlaceholder.string, text: $privateKeyString)
                        .foregroundColor(.primaryTxt)
                    ActionButton(title: Localized.save) {
                        if privateKeyString.isEmpty {
                            self.keyPair = nil
                            analytics.logout()
                            // just crash for now until we can fix the crash that happens when you log back in.
                            fatalError("Logged out")
                            // appController.configureCurrentState()
                        } else if let keyPair = KeyPair(nsec: privateKeyString) {
                            self.keyPair = keyPair
                            analytics.identify(with: keyPair)
                            analytics.changedKey()
                        } else {
                            self.keyPair = nil
                            showError = true
                        }
                    }
                    .padding(.vertical, 5)
                }
            } header: {
                Localized.keys.view
                    .foregroundColor(.textColor)
                    .fontWeight(.heavy)
                    .bold()
            }
            .listRowBackground(LinearGradient(
                colors: [Color.cardBgTop, Color.cardBgBottom],
                startPoint: .top,
                endPoint: .bottom
            ))
            
            #if DEBUG
            Section {
                Text(Localized.sampleDataInstructions.string)
                    .foregroundColor(.primaryTxt)
                
                Button(Localized.loadSampleData.string) {
                    PersistenceController.loadSampleData(context: viewContext)
                }
            } header: {
                Localized.debug.view
                    .foregroundColor(.textColor)
                    .fontWeight(.heavy)
                    .bold()
            }
            .listRowBackground(LinearGradient(
                colors: [Color.cardBgTop, Color.cardBgBottom],
                startPoint: .top,
                endPoint: .bottom
            ))
            #endif
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBg)
        .navigationBarTitle(Localized.settings.string, displayMode: .inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.cardBgBottom, for: .navigationBar)
        .alert(isPresented: $showError) {
            Alert(
                title: Localized.invalidKey.view,
                message: Localized.couldNotReadPrivateKeyMessage.view
            )
        }
        .task {
			if let privateKeyData = KeyChain.load(key: KeyChain.keychainPrivateKey),
                let keyPair = KeyPair(privateKeyHex: String(decoding: privateKeyData, as: UTF8.self)) {
                privateKeyString = keyPair.nsec
            } else {
                print("Could not load private key from keychain")
                privateKeyString = ""
            }
        }
        .onAppear {
            analytics.showedSettings()
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SettingsView()
        }
    }
}
