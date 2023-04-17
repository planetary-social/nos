//
//  SettingsView.swift
//  Nos
//
//  Created by Matthew Lorentz on 2/3/23.
//

import SwiftUI
import Dependencies
import SwiftUINavigation

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Dependency(\.analytics) private var analytics
    @EnvironmentObject private var appController: AppController
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var currentUser: CurrentUser

    @State private var privateKeyString = ""
    @State private var alert: AlertState<Never>?
    @State private var logFileURL: URL?
    
    func importKey(_ keyPair: KeyPair) async {
        await currentUser.setKeyPair(keyPair)
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
                            await currentUser.setKeyPair(nil)
                            analytics.logout()
                            appController.configureCurrentState()
                        } else if let keyPair = KeyPair(nsec: privateKeyString) {
                            await importKey(keyPair)
                        } else if let keyPair = KeyPair(privateKeyHex: privateKeyString) {
                            await importKey(keyPair)
                        } else {
                            await currentUser.setKeyPair(nil)
                            alert = AlertState(title: {
                                Localized.invalidKey.textState
                            }, message: {
                                Localized.couldNotReadPrivateKeyMessage.textState
                            })
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
            
            Section {
                HStack {
                    SecondaryActionButton(title: Localized.shareLogs) {
                        Task {
                            do {
                                logFileURL = try await LogHelper.zipLogs()
                            } catch {
                                alert = AlertState(title: {
                                    Localized.error.textState
                                }, message: {
                                    Localized.failedToExportLogs.textState
                                })
                            }
                        }
                    }        
                }
                .padding(.vertical, 5)
                .sheet(unwrapping: $logFileURL) { logFileURL in
                    ActivityViewController(activityItems: [logFileURL.wrappedValue])
                }

                #if DEBUG
                Text(Localized.sampleDataInstructions.string)
                    .foregroundColor(.primaryTxt)

                Button(Localized.loadSampleData.string) {
                    Task { await PersistenceController.loadSampleData(context: viewContext) }
                }
                #endif
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
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBg)
        .nosNavigationBar(title: .settings)
        .alert(unwrapping: $alert)
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
