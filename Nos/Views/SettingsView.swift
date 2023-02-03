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
            TextField("Private Key", text: $privateKeyString)
            Button("Save") {
                let keyPair = KeyPair(privateKeyString: privateKeyString)
                if keyPair.isValid {
                    self.keyPair = keyPair
                } else {
                    self.keyPair = nil
                    showError = true
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
            if let keyPair = self.keyPair, keyPair.isValid {
                privateKeyString = keyPair.privateKeyString
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
