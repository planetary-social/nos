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
    @State private var relaySubscriptions = SubscriptionCancellables()

    @State private var selectedTab: ProfileFeedType = .notes

    @State private var alert: AlertState<Never>?

    var isShowingLoggedInUser: Bool {
        author.hexadecimalPublicKey == currentUser.publicKeyHex
    }

    init(author: Author, addDoubleTapToPop: Bool = false) {
        self.author = author
        self.addDoubleTapToPop = addDoubleTapToPop
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

    private var title: AttributedString {
        let prefix = isShowingLoggedInUser ?
            String(localized: LocalizedStringResource.localizable.yourProfile) :
            String(localized: LocalizedStringResource.localizable.profileTitle)
        if author.muted {
            let suffix = "(\(String(localized: .localizable.muted).lowercased()))"
            var attributedString = AttributedString("\(prefix) \(suffix)")
            if let range = attributedString.range(of: suffix) {
                attributedString[range].foregroundColor = Color.secondaryTxt
            }
            return attributedString
        } else {
            return AttributedString(prefix)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack {
                PagedNoteListView(
                    databaseFilter: selectedTab.databaseFilter(author: author),
                    relayFilter: selectedTab.relayFilter(author: author),
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
                            
                            SecondaryActionButton(
                                title: .localizable.tapToRefresh
                            ) {
                                NotificationCenter.default.post(
                                    name: .refresh,
                                    object: nil,
                                    userInfo: ["tab": AppDestination.profile]
                                )
                            }
                        }
                        .frame(minHeight: 300)
                    },
                    onRefresh: {
                        selectedTab.databaseFilter(author: author)
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
        .nosNavigationBar(title: title)
        .navigationDestination(for: MutesDestination.self) { _ in
            MutesView()
        }
        .navigationDestination(for: FollowsDestination.self) { destination in
            FollowsView(title: .localizable.follows, authors: destination.follows)
        }
        .navigationDestination(for: FollowersDestination.self) { destination in
            FollowsView(title: .localizable.mutualFriends, authors: destination.followers)
        }
        .navigationDestination(for: RelaysDestination.self) { destination in
            RelayView(author: destination.author, editable: false)
        }
        .navigationDestination(for: EditProfileDestination.self) { destination in
            ProfileEditView(author: destination.profile)
        }
        .navigationBarItems(
            trailing:
                HStack {
                    Button(
                        action: {
                            showingOptions = true
                        },
                        label: {
                            Image(systemName: "ellipsis")
                        }
                    )
                    .reportMenu($showingReportMenu, reportedObject: .author(author))
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
                                    router.push(EditProfileDestination(profile: author))
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
                            
                            Button(String(localized: .localizable.flagUser)) {
                                showingReportMenu = true
                            }
                        }
                    }
                }
        )
        .alert(unwrapping: $alert)
        .onAppear {
            Task { 
                await downloadAuthorData()
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
