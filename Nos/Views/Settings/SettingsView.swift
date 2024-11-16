import SwiftUI
import Dependencies
import Logger
import SwiftUINavigation

let showReportWarningsKey = "com.verse.nos.settings.showReportWarnings"
let showOutOfNetworkWarningKey = "com.verse.nos.settings.showOutOfNetworkWarning"
    
struct SettingsView: View {
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
    @State private var showDeleteConfirmationAlert = false

    fileprivate enum AlertAction {
        case logout
        case deleteAccount
    }

    var body: some View {
        Form {
            Section {
                HStack {
                    Text(String(repeating: "•", count: 63))
                        .foregroundColor(.primaryTxt)
                        .font(.clarity(.regular, textStyle: .body))
                        .lineLimit(1)
                        .accessibilityLabel(Text("privateKey"))

                    Spacer()

                    // The ZStack ensures that the copy and copied buttons
                    // have the same width
                    ZStack {
                        // Copy Button
                        SecondaryActionButton(
                            "copy",
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
                            "copied",
                            shouldFillHorizontalSpace: true
                        )
                        .opacity(copyButtonState == .copied ? 1 : 0)
                        .disabled(true)
                    }
                    .fixedSize(horizontal: true, vertical: false)
                    .padding(.vertical, 5)
                }
                
                ActionButton("logout") {
                    alert = AlertState(
                        title: { TextState(String(localized: "logout")) },
                        actions: {
                            ButtonState(role: .destructive, action: .send(.logout)) {
                                TextState(String(localized: "myKeyIsBackedUp"))
                            }
                        },
                        message: { TextState(String(localized: "backUpYourKeyWarning")) }
                    )
                }
                .padding(.vertical, 5)
            } header: {
                VStack(alignment: .leading, spacing: 10) {
                    Text("privateKey")
                        .foregroundColor(.primaryTxt)
                        .font(.clarity(.semibold, textStyle: .headline))

                    Text("privateKeyWarning")
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
                    NosToggle("useReportsFromFollows", isOn: $showReportWarnings)
                        .onChange(of: showReportWarnings) { _, newValue in
                            userDefaults.set(newValue, forKey: showReportWarningsKey)
                        }
                    
                    HStack {
                        Text("useReportsFromFollowsDescription")
                            .foregroundColor(.secondaryTxt)
                            .font(.footnote)
                        Spacer()
                    }
                }
                .padding(.bottom, 8)
                
                VStack {
                    NosToggle("showOutOfNetworkWarnings", isOn: $showOutOfNetworkWarning)
                        .onChange(of: showOutOfNetworkWarning) { _, newValue in
                            userDefaults.set(newValue, forKey: showOutOfNetworkWarningKey)
                        }
                    
                    HStack {
                        Text("showOutOfNetworkWarningsDescription")
                            .foregroundColor(.secondaryTxt)
                            .font(.footnote)
                        Spacer()
                    }
                }
                .padding(.bottom, 8)
            } header: {
                Text("feedSettings")
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
                Text("\(String(localized: "appVersion")) \(Bundle.current.versionAndBuild)")
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

                SecondaryActionButton("shareDatabase") {
                    Task {
                        do {
                            fileToShare = try await Zipper.zipDatabase(controller: persistenceController)
                        } catch {
                            alert = AlertState(title: {
                                TextState(String(localized: "error"))
                            }, message: {
                                TextState(String(localized: "failedToShareDatabase"))
                            })
                        }
                    }
                }

                SecondaryActionButton("shareLogs") {
                    Task {
                        do {
                            fileToShare = try await Zipper.zipLogs()
                        } catch {
                            alert = AlertState(title: {
                                TextState(String(localized: "error"))
                            }, message: {
                                TextState(String(localized: "failedToExportLogs"))
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
                Text("debug")
                    .foregroundColor(.primaryTxt)
                    .font(.clarity(.semibold, textStyle: .headline))
                    .textCase(nil)
                    .listRowInsets(EdgeInsets())
                    .padding(.vertical, 15)
            }
            .listRowGradientBackground()

            ActionButton(
                "deleteMyAccount",
                font: .clarityBold(.title3),
                padding: EdgeInsets(top: 16, leading: 0, bottom: 16, trailing: 0),
                depthEffectColor: .actionSecondaryDepthEffect,
                backgroundGradient: .verticalAccentSecondary,
                shouldFillHorizontalSpace: true
            ) {
                showDeleteConfirmationAlert = true
            }
            .clipShape(Capsule())
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBg)
        .nosNavigationBar("settings")
        .alert(unwrapping: $alert) { (action: AlertAction?) in
            if let action {
                await alertButtonTapped(action)
            }
        }
        .onAppear {
            privateKeyString = currentUser.keyPair?.nsec ?? ""
            analytics.showedSettings()
        }
        .overlay {
            ZStack {
                if showDeleteConfirmationAlert {
                    /// Adds a translucent background overlay to the view's man content
                    Color.actionSheetOverlay.opacity(0.5)
                        .ignoresSafeArea()
                    
                    DeleteConfirmationView(
                        requiredText: String(localized: "delete").uppercased(),
                        onDelete: {
                            Task {
                                await alertButtonTapped(.deleteAccount)
                            }
                            showDeleteConfirmationAlert = false
                        },
                        onCancel: {
                            showDeleteConfirmationAlert = false
                        }
                    )
                }
            }                    
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.2), value: showDeleteConfirmationAlert)
        }
    }

    fileprivate func alertButtonTapped(_ action: AlertAction) async {
        switch action {
        case .logout:
            await currentUser.logout(appController: appController)
        case .deleteAccount:
            do {
                try await currentUser.deleteAccount(appController: appController)
            } catch {
                Log.error(error)
            }
        }
    }
}

// DEBUG builds will have everything that's in STAGING builds and more.
#if STAGING || DEBUG
extension SettingsView {
    /// Whether the new onboarding flow is enabled.
    private var isNewOnboardingFlowEnabled: Binding<Bool> {
        Binding<Bool>(
            get: { featureFlags.isEnabled(.newOnboardingFlow) },
            set: { featureFlags.setFeature(.newOnboardingFlow, enabled: $0) }
        )
    }

    /// A toggle for the new moderation flow that allows the user to turn the feature on or off.
    private var newOnboardingFlowToggle: some View {
        NosToggle("New Onboarding Flow", isOn: isNewOnboardingFlowEnabled)
    }
}
#endif

#if STAGING
extension SettingsView {
    /// Controls that will appear when the app is built for STAGING.
    @MainActor private var stagingControls: some View {
        Group {
            newOnboardingFlowToggle
        }
    }
}
#endif

#if DEBUG
extension SettingsView {
    /// Controls that will appear when the app is built for DEBUG.
    @MainActor private var debugControls: some View {
        Group {
            newOnboardingFlowToggle
            Text("sampleDataInstructions")
                .foregroundColor(.primaryTxt)
            Button("loadSampleData") {
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
                    Text("allPublishedEvents")
                }
            }
            
            NavigationLink {
                SensitiveImageSettingView()
            } label: {
                Text("Sensitive Content")
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
