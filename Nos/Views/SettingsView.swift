//
//  SettingsView.swift
//  Nos
//
//  Created by Matthew Lorentz on 2/3/23.
//

import SwiftUI

struct SettingsView: View {
    
    // TODO: store private key in keychain
    @AppStorage("keyPair") private var keyPair: KeyPair?
    
    @State var privateKeyString = ""
    
    @State var showError = false
    
    var body: some View {
        Form {
            Section(Localized.keys.string) {
                Localized.keyEncryptionWarning.view
                TextField(Localized.privateKeyPlaceholder.string, text: $privateKeyString)
                Button(Localized.save.string) {
                    if let keyPair = KeyPair(privateKeyHex: privateKeyString) {
                        self.keyPair = keyPair
                    } else {
                        self.keyPair = nil
                        showError = true
                    }
                }
            }
        }
        .navigationTitle(Localized.settings.string)
        .alert(isPresented: $showError) {
            Alert(
                title: Localized.invalidKey.view,
                message: Localized.couldNotReadPrivateKeyMessage.view
            )
        }
        .task {
            if let keyPair = self.keyPair {
                privateKeyString = keyPair.privateKeyHex
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
