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
    @Dependency(\.featureFlags) private var featureFlags
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(AppController.self) var appController
    @Environment(CurrentUser.self) private var currentUser

    @State private var privateKeyString = ""
    @State private var alert: AlertState<AlertAction>?
    @State private var fileToShare: URL?
    private var showActivitySheet: Binding<Bool> {
        Binding<Bool>(
            get: { fileToShare != nil },
            set: { _ in }
        )
    }

    @State private var showReportWarnings = true
    @State private var showOutOfNetworkWarning = true
    @State private var copyButtonState: CopyButtonState = .copy
    @State private var copyButtonWidth: CGFloat = 0

    fileprivate enum AlertAction {
        case logout
    }

    fileprivate enum CopyButtonState {
        case copy
        case copied
    }

    var body: some View {
        Form {
            Section {
                HStack {
                    Text(String(repeating: "•", count: 63))
                        .foregroundColor(.primaryTxt)
                        .font(.clarity(.regular, textStyle: .body))
                        .lineLimit(1)
                        .accessibilityLabel(Text(.localizable.privateKey))

                    Spacer()

                    // The ZStack ensures that the copy and copied buttons
                    // have the same width
                    ZStack {
                        // Copy Button
                        SecondaryActionButton(
                            title: .localizable.copy,
                            image: .copyIcon,
                            imageAlignment: .right,
                            shouldFillHorizontalSpace: true
                        ) {
                            UIPasteboard.general.string = privateKeyString
                            copyButtonState = .copied
                            Task { @MainActor in
                                try await Task.sleep(for: .seconds(10))
                                copyButtonState = .copy
                            }
                        }
                        .opacity(copyButtonState == .copy ? 1 : 0)

                        // Copied Button
                        SecondaryActionButton(
                            title: .localizable.copied,
                            shouldFillHorizontalSpace: true
                        )
                        .opacity(copyButtonState == .copied ? 1 : 0)
                        .disabled(true)
                    }
                    .fixedSize(horizontal: true, vertical: false)
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
                    Text(.localizable.privateKey)
                        .foregroundColor(.primaryTxt)
                        .font(.clarity(.semibold, textStyle: .headline))

                    Text(.localizable.privateKeyWarning)
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
                        Text(.localizable.useReportsFromFollows)
                            .foregroundColor(.primaryTxt)
                    }
                    .onChange(of: showReportWarnings) { _, newValue in
                        userDefaults.set(newValue, forKey: showReportWarningsKey)
                    }
                    
                    HStack {
                        Text(.localizable.useReportsFromFollowsDescription)
                            .foregroundColor(.secondaryTxt)
                            .font(.footnote)
                        Spacer()
                    }
                }
                .padding(.bottom, 8)

                VStack {
                    Toggle(isOn: $showOutOfNetworkWarning) { 
                        Text(.localizable.showOutOfNetworkWarnings)
                            .foregroundColor(.primaryTxt)
                    }
                    .onChange(of: showOutOfNetworkWarning) { _, newValue in
                        userDefaults.set(newValue, forKey: showOutOfNetworkWarningKey)
                    }
                    
                    HStack {
                        Text(.localizable.showOutOfNetworkWarningsDescription)
                            .foregroundColor(.secondaryTxt)
                            .font(.footnote)
                        Spacer()
                    }
                }
                .padding(.bottom, 8)
            } header: {
                Text(.localizable.feedSettings)
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
                Text("\(String(localized: .localizable.appVersion)) \(Bundle.current.versionAndBuild)")
                    .foregroundColor(.primaryTxt)
                    .padding(.vertical, 5)
                    .sheet(
                        isPresented: showActivitySheet,
                        onDismiss: {
                            fileToShare = nil
                        },
                        content: {
                            if let fileToShare {
                                ActivityViewController(activityItems: [fileToShare])
                            } else {
                                EmptyView()
                            }
                        }
                    )

                SecondaryActionButton(title: .localizable.shareDatabase) {
                    if let url = persistenceController.sqliteURL() {
                        fileToShare = url
                    } else {
                        alert = AlertState(title: {
                            TextState(String(localized: .localizable.error))
                        }, message: {
                            TextState(String(localized: .localizable.failedToShareDatabase))
                        })
                    }
                }

                SecondaryActionButton(title: .localizable.shareLogs) {
                    Task {
                        do {
                            fileToShare = try await LogHelper.zipLogs()
                        } catch {
                            alert = AlertState(title: {
                                TextState(String(localized: .localizable.error))
                            }, message: {
                                TextState(String(localized: .localizable.failedToExportLogs))
                            })
                        }
                    }
                }

                #if DEBUG
                debugControls
                #endif
            } header: {
                Text(.localizable.debug)
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

#if DEBUG
extension SettingsView {
    private var enableNewMediaDisplay: Binding<Bool> {
        Binding<Bool>(
            get: { featureFlags.newMediaDisplayEnabled },
            set: { featureFlags.setNewMediaDisplayEnabled($0) }
        )
    }

    @MainActor var debugControls: some View {
        Group {
            Toggle(isOn: enableNewMediaDisplay) {
                Text(.localizable.enableNewMediaDisplay)
                    .foregroundColor(.primaryTxt)
            }

            Text(.localizable.sampleDataInstructions)
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
                    Text(.localizable.allPublishedEvents)
                }
            }
        }
    }
}
#endif

#Preview {
    let previewData = PreviewData()
    
    return NavigationStack {
        SettingsView()
    }
    .inject(previewData: previewData)
    .environment(AppController())
}
