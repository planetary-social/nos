//
//  SettingsView.swift
//  Nos
//
//  Created by Matthew Lorentz on 2/3/23.
//

import SwiftUI

struct SettingsView: View {
    

    
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
            if let privateKeyData = KeyChain.load(key: KeyChain.keychainPrivateKey),
               let hexString = NSString(data: privateKeyData, encoding: NSUTF8StringEncoding) as? String {
                privateKeyString = hexString
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
