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
    @Dependency(\.crashReporting) private var crashReporting
    @Dependency(\.persistenceController) private var persistenceController
    @EnvironmentObject private var appController: AppController
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var currentUser: CurrentUser

    @State private var privateKeyString = ""
    @State private var alert: AlertState<AlertAction>?
    @State private var logFileURL: URL?
    
    func importKey(_ keyPair: KeyPair) async {
        await currentUser.setKeyPair(keyPair)
        analytics.identify(with: keyPair)
        crashReporting.identify(with: keyPair)
        analytics.changedKey()
    }
    
    fileprivate enum AlertAction {
        case logout
    }
    
    var body: some View {
        Form {
            Section {
                HStack {
                    SecureField(Localized.privateKeyPlaceholder.string, text: $privateKeyString)
                        .foregroundColor(.primaryTxt)
                    
                    SecondaryActionButton(title: Localized.save) {
                        if privateKeyString.isEmpty {
                            await logout()
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

                    SecondaryActionButton(title: Localized.copy) {
                        UIPasteboard.general.string = privateKeyString
                    }
                    .padding(.vertical, 5)
                }
                
                ActionButton(title: Localized.logout) {
                    alert = AlertState(
                        title: { Localized.logout.textState }, 
                        actions: {
                            ButtonState(role: .destructive, action: .send(.logout)) {
                                Localized.myKeyIsBackedUp.textState
                            }
                        },
                        message: { Localized.backUpYourKeyWarning.textState }
                    )
                }        
                .padding(.vertical, 5)
            } header: {
                VStack(alignment: .leading, spacing: 10) {
                    Localized.privateKey.view
                        .foregroundColor(.textColor)
                        .bold()
                    
                    Localized.privateKeyWarning.view
                        .foregroundColor(.secondaryText)
                }
                .textCase(nil)
                .padding(.vertical, 15)
            }
            .listRowBackground(LinearGradient(
                colors: [Color.cardBgTop, Color.cardBgBottom],
                startPoint: .top,
                endPoint: .bottom
            ))
            
            Section {
                HStack {
                    Text("\(Localized.appVersion.string) \(Bundle.current.versionAndBuild)")
                        .foregroundColor(.primaryTxt)
                    Spacer()
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
                    Task {
                        do {
                            try await persistenceController.loadSampleData(context: viewContext)
                        } catch {
                            print(error)
                        }
                    }
                }
                if let author = currentUser.author {
                    NavigationLink {
                        PublishedEventsView(author: author)
                    } label: {
                        Localized.allPublishedEvents.view
                    }
                }
                #endif
            } header: {
                Localized.debug.view
                    .foregroundColor(.textColor)
                    .fontWeight(.heavy)
                    .bold()
                    .textCase(nil)
                    .padding(.vertical, 15)
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
        .alert(unwrapping: $alert) { (action: AlertAction?) in
            if let action {
                await alertButtonTapped(action)
            }
        }
        .onAppear {
            privateKeyString = currentUser.keyPair?.nsec ?? ""
            analytics.showedSettings()
        }
    }
    
    fileprivate func alertButtonTapped(_ action: AlertAction) async {
        switch action {
        case .logout:
            await logout()
        }
    }
    
    func logout() async {
        await currentUser.setKeyPair(nil)
        analytics.logout()
        crashReporting.logout()
        appController.configureCurrentState() 
    }
}

struct SettingsView_Previews: PreviewProvider {
    
    static var previews: some View {
        NavigationStack {
            SettingsView()
        }
    }
}
