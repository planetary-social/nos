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
            Section(Localized.keys.string) {
                Localized.keyEncryptionWarning.view
                TextField(Localized.privateKeyPlaceholder.string, text: $privateKeyString)
                Button(Localized.save.string) {
                    if privateKeyString.isEmpty {
                        self.keyPair = nil
                        analytics.logout()
                        appController.configureCurrentState()
                    } else if let keyPair = KeyPair(nsec: privateKeyString) {
                        self.keyPair = keyPair
                        analytics.identify(with: keyPair)
                        analytics.changedKey()
                    } else {
                        self.keyPair = nil
                        showError = true
                    }
                }
            }
            #if DEBUG
            Section(Localized.debug.string) {
                Text(Localized.sampleDataInstructions.string)
                Button(Localized.loadSampleData.string) {
                    PersistenceController.loadSampleData(context: viewContext)
                }
            }
            #endif
        }
        .navigationBarTitle(Localized.settings.string, displayMode: .inline)
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
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SettingsView()
        }
    }
}
