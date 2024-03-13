import SwiftUI
import CoreData
import Dependencies
import SwiftUINavigation
import Logger

struct ProfileView: View {
    
    @ObservedObject var author: Author
    var addDoubleTapToPop = false

    @Environment(\.managedObjectContext) private var viewContext
    @Environment(CurrentUser.self) private var currentUser
    @EnvironmentObject private var router: Router
    @Dependency(\.relayService) private var relayService: RelayService
    @Dependency(\.analytics) private var analytics
    @Dependency(\.unsAPI) private var unsAPI
    
    @State private var showingOptions = false
    @State private var showingReportMenu = false
    @State private var usbcAddress: USBCAddress?
    @State private var usbcBalance: Double?
    @State private var usbcBalanceTimer: Timer?
    @State private var relaySubscriptions = SubscriptionCancellables()

    @State private var selectedTab: ProfileHeader.ProfileHeaderTab = .notes

    @State private var alert: AlertState<Never>?

    var isShowingLoggedInUser: Bool {
        author.hexadecimalPublicKey == currentUser.publicKeyHex
    }

    init(author: Author, addDoubleTapToPop: Bool = false) {
        self.author = author
        self.addDoubleTapToPop = addDoubleTapToPop
    }

    func loadUSBCBalance() async {
        guard let unsName = author.uns, !unsName.isEmpty else {
            usbcAddress = nil
            usbcBalance = nil
            usbcBalanceTimer?.invalidate()
            usbcBalanceTimer = nil
            return
        }
        do {
            usbcAddress = try await unsAPI.usbcAddress(for: unsName)
            if isShowingLoggedInUser {
                usbcBalance = try await unsAPI.usbcBalance(for: unsName)
                currentUser.usbcAddress = usbcAddress
                usbcBalanceTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
                    Task { @MainActor in 
                        usbcBalance = try await unsAPI.usbcBalance(for: unsName) 
                    }
                }
            }
        } catch {
            Log.optional(error, "Failed to load USBC balance for \(author.hexadecimalPublicKey ?? "null")")
        }
    }
    
    func downloadAuthorData() async {
        relaySubscriptions.removeAll()
        
        guard let authorKey = author.hexadecimalPublicKey else {
            return
        }
        
        // Profile data
        relaySubscriptions.append(
            await relayService.requestProfileData(
                for: authorKey, 
                lastUpdateMetadata: author.lastUpdatedMetadata, 
                lastUpdatedContactList: nil // always grab contact list because we purge follows aggressively
            )
        )
        
        // reports
        let reportFilter = Filter(kinds: [.report], pTags: [authorKey])
        relaySubscriptions.append(await relayService.subscribeToEvents(matching: reportFilter)) 
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack {
                let profileNotesFilter = Filter(
                    authorKeys: [author.hexadecimalPublicKey ?? "error"],
                    kinds: [.text, .delete, .repost, .longFormContent]
                )
                
                PagedNoteListView(
                    databaseFilter: selectedTab.request(author: author),
                    relayFilter: profileNotesFilter,
                    context: viewContext,
                    tab: .profile,
                    header: {
                        ProfileHeader(author: author, selectedTab: $selectedTab)
                            .compositingGroup()
                            .shadow(color: .profileShadow, radius: 10, x: 0, y: 4)
                    },
                    emptyPlaceholder: {
                        VStack {
                            Text(.localizable.noEventsOnProfile)
                                .padding()
                                .readabilityPadding()
                        }
                        .frame(minHeight: 300)
                    },
                    onRefresh: {
                        selectedTab.request(author: author)
                    }
                )
                .padding(0)
                .id(selectedTab)
            }
            .doubleTapToPop(tab: .profile, enabled: addDoubleTapToPop) { _ in
                NotificationCenter.default.post(
                    name: .scrollToTop,
                    object: nil,
                    userInfo: ["tab": AppDestination.profile]
                )
            }
        }
        .background(Color.appBg)
        .nosNavigationBar(title: LocalizedStringResource(stringLiteral: author.safeIdentifier))
        .navigationDestination(for: Event.self) { note in
            RepliesView(note: note)
        }                  
        .navigationDestination(for: URL.self) { url in URLView(url: url) }
        .navigationDestination(for: ReplyToNavigationDestination.self) { destination in
            RepliesView(note: destination.note, showKeyboard: true)
        }
        .navigationDestination(for: MutesDestination.self) { _ in
            MutesView()
        }
        .navigationDestination(for: FollowsDestination.self) { destination in
            FollowsView(title: .localizable.follows, authors: destination.follows)
        }
        .navigationDestination(for: FollowersDestination.self) { destination in
            FollowsView(title: .localizable.followers, authors: destination.followers)
        }
        .navigationDestination(for: RelaysDestination.self) { destination in
            RelayView(author: destination.author, editable: false)
        }
        .navigationBarItems(
            trailing:
                HStack {
                    if usbcBalance != nil {
                        USBCBalanceBarButtonItem(balance: $usbcBalance)
                    } else if let usbcAddress, !isShowingLoggedInUser {
                        SendUSBCBarButtonItem(destinationAddress: usbcAddress, destinationAuthor: author)
                    }
                    Button(
                        action: {
                            showingOptions = true
                        },
                        label: {
                            Image(systemName: "ellipsis")
                        }
                    )
                    .confirmationDialog(String(localized: .localizable.share), isPresented: $showingOptions) {
                        Button(String(localized: .localizable.copyUserIdentifier)) {
                            UIPasteboard.general.string = author.publicKey?.npub ?? ""
                        }
                        Button(String(localized: .localizable.copyLink)) {
                            UIPasteboard.general.string = author.webLink
                        }
                        if isShowingLoggedInUser {
                            Button(
                                action: {
                                    currentUser.editing = true
                                    router.push(author)
                                },
                                label: {
                                    Text(.localizable.editProfile)
                                }
                            )
                            Button(
                                action: {
                                    router.push(MutesDestination())
                                },
                                label: {
                                    Text(.localizable.mutedUsers)
                                }
                            )
                        } else {
                            if author.muted {
                                Button(String(localized: .localizable.unmuteUser)) {
                                    Task {
                                        do {
                                            try await author.unmute(viewContext: viewContext)
                                        } catch {
                                            alert = AlertState(title: {
                                                TextState(String(localized: .localizable.error))
                                            }, message: {
                                                TextState(error.localizedDescription)
                                            })
                                        }
                                    }
                                }
                            } else {
                                Button(String(localized: .localizable.mute)) {
                                    Task { @MainActor in
                                        do {
                                            try await author.mute(viewContext: viewContext)
                                        } catch {
                                            alert = AlertState(title: {
                                                TextState(String(localized: .localizable.error))
                                            }, message: {
                                                TextState(error.localizedDescription)
                                            })
                                        }
                                    }
                                }
                            }
                            
                            Button(String(localized: .localizable.reportUser), role: .destructive) {
                                showingReportMenu = true
                            }
                        }
                    }
                }
        )
        .reportMenu($showingReportMenu, reportedObject: .author(author))
        .onChange(of: author.uns) { 
            Task {
                await loadUSBCBalance()
            }
        }
        .alert(unwrapping: $alert)
        .onAppear {
            Task { 
                await downloadAuthorData()
                await loadUSBCBalance() 
            }
            analytics.showedProfile()
        }
        .onDisappear {
            relaySubscriptions.removeAll()
        }
    }
}

#Preview("Generic user") {
    var previewData = PreviewData()
    
    return NavigationStack {
        ProfileView(author: previewData.previewAuthor)
    }
    .inject(previewData: previewData)
}

#Preview("UNS") {
    var previewData = PreviewData()
    
    return NavigationStack {
        ProfileView(author: previewData.eve)
    }
    .inject(previewData: previewData)
}

#Preview("Logged in User") {
    
    @Dependency(\.persistenceController) var persistenceController 
    
    lazy var previewContext: NSManagedObjectContext = {
        persistenceController.container.viewContext  
    }()

    lazy var currentUser: CurrentUser = {
        let currentUser = CurrentUser()
        currentUser.viewContext = previewContext
        Task { await currentUser.setKeyPair(KeyFixture.eve) }
        return currentUser
    }() 
    
    var previewData = PreviewData(currentUser: currentUser)
    
    return NavigationStack {
        ProfileView(author: previewData.eve)
    }
    .inject(previewData: previewData)
}
