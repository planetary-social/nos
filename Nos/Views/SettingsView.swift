import SwiftUI
import Dependencies
import SwiftUINavigation

let showReportWarningsKey = "com.verse.nos.settings.showReportWarnings"
let showOutOfNetworkWarningKey = "com.verse.nos.settings.showOutOfNetworkWarning"
    
struct SettingsView: View {
    @Dependency(\.unsAPI) var unsAPI
    @Dependency(\.analytics) private var analytics
    @Dependency(\.crashReporting) private var crashReporting
    @Dependency(\.persistenceController) private var persistenceController
    @Dependency(\.userDefaults) private var userDefaults
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(AppController.self) var appController
    @EnvironmentObject private var router: Router
    @Environment(CurrentUser.self) private var currentUser

    @State private var privateKeyString = ""
    @State private var alert: AlertState<AlertAction>?
    @State private var logFileURL: URL?
    @State private var showReportWarnings = true
    @State private var showOutOfNetworkWarning = true
    
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
                    SecureField(String(localized: .localizable.privateKeyPlaceholder), text: $privateKeyString)
                        .foregroundColor(.primaryTxt)
                        .font(.clarity(.regular, textStyle: .body))

                    SecondaryActionButton(title: .localizable.save) {
                        if privateKeyString.isEmpty {
                            await logout()
                        } else if let keyPair = KeyPair(nsec: privateKeyString) {
                            await importKey(keyPair)
                        } else if let keyPair = KeyPair(privateKeyHex: privateKeyString) {
                            await importKey(keyPair)
                        } else {
                            await currentUser.setKeyPair(nil)
                            alert = AlertState(title: {
                                TextState(String(localized: .localizable.invalidKey))
                            }, message: {
                                TextState(String(localized: .localizable.couldNotReadPrivateKeyMessage))
                            })
                        }
                    }
                    .padding(.vertical, 5)

                    SecondaryActionButton(title: .localizable.copy) {
                        UIPasteboard.general.string = privateKeyString
                    }
                    .padding(.vertical, 5)
                }
                
                ActionButton(title: .localizable.logout) {
                    alert = AlertState(
                        title: { TextState(String(localized: .localizable.logout)) },
                        actions: {
                            ButtonState(role: .destructive, action: .send(.logout)) {
                                TextState(String(localized: .localizable.myKeyIsBackedUp))
                            }
                        },
                        message: { TextState(String(localized: .localizable.backUpYourKeyWarning)) }
                    )
                }        
                .padding(.vertical, 5)
            } header: {
                VStack(alignment: .leading, spacing: 10) {
                    PlainText(.localizable.privateKey)
                        .foregroundColor(.primaryTxt)
                        .font(.clarity(.semibold, textStyle: .headline))

                    PlainText(.localizable.privateKeyWarning)
                        .foregroundColor(.secondaryTxt)
                        .font(.footnote)
                }
                .textCase(nil)
                .listRowInsets(EdgeInsets())
                .padding(.top, 30)
                .padding(.bottom, 20)
            }
            .listRowBackground(LinearGradient(
                colors: [Color.cardBgTop, Color.cardBgBottom],
                startPoint: .top,
                endPoint: .bottom
            ))
            
            Section {
                VStack {
                    Toggle(isOn: $showReportWarnings) { 
                        PlainText(.localizable.useReportsFromFollows)
                            .foregroundColor(.primaryTxt)
                    }
                    .onChange(of: showReportWarnings) { _, newValue in
                        userDefaults.set(newValue, forKey: showReportWarningsKey)
                    }
                    
                    HStack {
                        PlainText(.localizable.useReportsFromFollowsDescription)
                            .foregroundColor(.secondaryTxt)
                            .font(.footnote)
                        Spacer()
                    }
                }
                .padding(.bottom, 8)

                VStack {
                    Toggle(isOn: $showOutOfNetworkWarning) { 
                        PlainText(.localizable.showOutOfNetworkWarnings)
                            .foregroundColor(.primaryTxt)
                    }
                    .onChange(of: showOutOfNetworkWarning) { _, newValue in
                        userDefaults.set(newValue, forKey: showOutOfNetworkWarningKey)
                    }
                    
                    HStack {
                        PlainText(.localizable.showOutOfNetworkWarningsDescription)
                            .foregroundColor(.secondaryTxt)
                            .font(.footnote)
                        Spacer()
                    }
                }
                .padding(.bottom, 8)
            } header: {
                PlainText(.localizable.feedSettings)
                    .foregroundColor(.primaryTxt)
                    .font(.clarity(.semibold, textStyle: .headline))
                    .textCase(nil)
                    .listRowInsets(EdgeInsets())
                    .padding(.vertical, 15)
            }
            .listRowBackground(LinearGradient(
                colors: [Color.cardBgTop, Color.cardBgBottom],
                startPoint: .top,
                endPoint: .bottom
            ))
            .task {
                showReportWarnings = userDefaults.object(forKey: showReportWarningsKey) as? Bool ?? true
                showOutOfNetworkWarning = userDefaults.object(forKey: showOutOfNetworkWarningKey) as? Bool ?? true
            }
            
            Section {
                HStack {
                    PlainText("\(String(localized: .localizable.appVersion)) \(Bundle.current.versionAndBuild)")
                        .foregroundColor(.primaryTxt)
                    Spacer()
                    SecondaryActionButton(title: .localizable.shareLogs) {
                        Task {
                            do {
                                logFileURL = try await LogHelper.zipLogs()
                            } catch {
                                alert = AlertState(title: {
                                    TextState(String(localized: .localizable.error))
                                }, message: {
                                    TextState(String(localized: .localizable.failedToExportLogs))
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
                PlainText(.localizable.sampleDataInstructions)
                    .foregroundColor(.primaryTxt)
                Button(String(localized: .localizable.loadSampleData)) {
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
                        PlainText(.localizable.allPublishedEvents)
                    }
                }
                #endif
            } header: {
                PlainText(.localizable.debug)
                    .foregroundColor(.primaryTxt)
                    .font(.clarity(.semibold, textStyle: .headline))
                    .textCase(nil)
                    .listRowInsets(EdgeInsets())
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
        .nosNavigationBar(title: .localizable.settings)
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
        unsAPI.logout()
        appController.configureCurrentState() 
    }
}

#Preview {
    let previewData = PreviewData()
    
    return NavigationStack {
        SettingsView()
    }
    .inject(previewData: previewData)
}
