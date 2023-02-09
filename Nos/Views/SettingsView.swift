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
            Section("Keys") {
                Text("Warning: your private key will be stored unencrypted on disk. ")
                TextField("Private Key (in hex format)", text: $privateKeyString)
                Button("Save") {
                    if let keyPair = KeyPair(privateKeyHex: privateKeyString) {
                        self.keyPair = keyPair
                    } else {
                        self.keyPair = nil
                        showError = true
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .alert(isPresented: $showError) {
            Alert(
                title: Text("Invalid Key"),
                message: Text("Could not read your private key. Make sure it is in hex format.")
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
