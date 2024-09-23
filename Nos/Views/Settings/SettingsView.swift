import SwiftUI
import Dependencies
import Logger
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

    fileprivate enum AlertAction {
        case logout
        case deleteAccount
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
            .listRowGradientBackground()
            
            Section {
                VStack {
                    NosToggle(isOn: $showReportWarnings, labelText: .localizable.useReportsFromFollows)
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
                    NosToggle(isOn: $showOutOfNetworkWarning, labelText: .localizable.showOutOfNetworkWarnings)
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
            .listRowGradientBackground()
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
                    Task {
                        do {
                            fileToShare = try await Zipper.zipDatabase(controller: persistenceController)
                        } catch {
                            alert = AlertState(title: {
                                TextState(String(localized: .localizable.error))
                            }, message: {
                                TextState(String(localized: .localizable.failedToShareDatabase))
                            })
                        }
                    }
                }

                SecondaryActionButton(title: .localizable.shareLogs) {
                    Task {
                        do {
                            fileToShare = try await Zipper.zipLogs()
                        } catch {
                            alert = AlertState(title: {
                                TextState(String(localized: .localizable.error))
                            }, message: {
                                TextState(String(localized: .localizable.failedToExportLogs))
                            })
                        }
                    }
                }

                #if STAGING
                stagingControls
                #endif

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
            .listRowGradientBackground()
            
            #if STAGING || DEBUG
            if isDeleteAccountEnabled.wrappedValue {
                ActionButton(
                    title: .localizable.deleteMyAccount,
                    font: .clarityBold(.title3),
                    padding: EdgeInsets(top: 16, leading: 0, bottom: 16, trailing: 0),
                    depthEffectColor: .actionSecondaryDepthEffect,
                    backgroundGradient: .verticalAccentSecondary,
                    shouldFillHorizontalSpace: true
                ) {
                    alert = AlertState(
                        title: { TextState(String(localized: .localizable.deleteAccount)) },
                        actions: {
                            ButtonState(role: .destructive, action: .send(.deleteAccount)) {
                                TextState(String(localized: .localizable.delete))
                            }
                        },
                        message: { TextState(String(localized: .localizable.deleteAccountDescription)) }
                    )
                }
                .clipShape(Capsule())
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }
        #endif
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
        case .deleteAccount:
            do {
                try await currentUser.publishRequestToVanish()
                await logout()
            } catch {
                Log.error(error)
            }
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

// DEBUG builds will have everything that's in STAGING builds and more.
#if STAGING || DEBUG
extension SettingsView {
    /// Whether the new media display is enabled.
    private var isNewMediaDisplayEnabled: Binding<Bool> {
        Binding<Bool>(
            get: { featureFlags.isEnabled(.newMediaDisplay) },
            set: { featureFlags.setFeature(.newMediaDisplay, enabled: $0) }
        )
    }

    /// A toggle for the new media display that allows the user to turn the feature on or off.
    private var newMediaFeatureToggle: some View {
        NosToggle(isOn: isNewMediaDisplayEnabled, labelText: .localizable.enableNewMediaDisplay)
    }

    /// Whether the new moderation flow is enabled.
    private var isNewModerationFlowEnabled: Binding<Bool> {
        Binding<Bool>(
            get: { featureFlags.isEnabled(.newModerationFlow) },
            set: { featureFlags.setFeature(.newModerationFlow, enabled: $0) }
        )
    }

    /// A toggle for the new moderation flow that allows the user to turn the feature on or off.
    private var newModerationFlowToggle: some View {
        NosToggle(isOn: isNewModerationFlowEnabled, labelText: .localizable.enableNewModerationFlow)
    }
    
    /// Whether account deletion is enabled.
    private var isDeleteAccountEnabled: Binding<Bool> {
        Binding<Bool>(
            get: { featureFlags.isEnabled(.deleteAccount) },
            set: { featureFlags.setFeature(.deleteAccount, enabled: $0) }
        )
    }
    
    /// A toggle for account deletion that allows the user to turn the feature on or off.
    private var deleteAccountToggle: some View {
        NosToggle(isOn: isDeleteAccountEnabled, labelText: .localizable.enableAccountDeletion)
    }
}
#endif

#if STAGING
extension SettingsView {
    /// Controls that will appear when the app is built for STAGING.
    @MainActor private var stagingControls: some View {
        Group {
            newMediaFeatureToggle
            newModerationFlowToggle
            deleteAccountToggle
        }
    }
}
#endif

#if DEBUG
extension SettingsView {
    /// Controls that will appear when the app is built for DEBUG.
    @MainActor private var debugControls: some View {
        Group {
            newMediaFeatureToggle
            newModerationFlowToggle
            deleteAccountToggle
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
