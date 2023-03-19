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
    @EnvironmentObject private var currentUser: CurrentUser

    @State var privateKeyString = ""
    
    @State var showError = false
    
    func importKey(_ keyPair: KeyPair) {
        currentUser.keyPair = keyPair
        analytics.identify(with: keyPair)
        analytics.changedKey()
    }
    
    var body: some View {
        Form {
            Section {
                Localized.keyEncryptionWarning.view
                    .foregroundColor(.primaryTxt)
                HStack {
                    SecureField(Localized.privateKeyPlaceholder.string, text: $privateKeyString)
                        .foregroundColor(.primaryTxt)
                    
                    ActionButton(title: Localized.save) {
                        if privateKeyString.isEmpty {
                            currentUser.keyPair = nil
                            analytics.logout()
                            appController.configureCurrentState()
                        } else if let keyPair = KeyPair(nsec: privateKeyString) {
                            importKey(keyPair)
                        } else if let keyPair = KeyPair(privateKeyHex: privateKeyString) {
                            importKey(keyPair)
                        } else {
                            currentUser.keyPair = nil
                            showError = true
                        }
                    }
                    .padding(.vertical, 5)
                    
                    ActionButton(title: Localized.copy) {
                        UIPasteboard.general.string = privateKeyString
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
        .nosNavigationBar(title: .settings)
        .alert(isPresented: $showError) {
            Alert(
                title: Localized.invalidKey.view,
                message: Localized.couldNotReadPrivateKeyMessage.view
            )
        }
        .onAppear {
            privateKeyString = currentUser.keyPair?.nsec ?? ""
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
