import SwiftUI
import CoreData
import Dependencies
import SwiftUINavigation
import Logger

struct ProfileView: View {
    
    @ObservedObject var author: Author
    let addDoubleTapToPop: Bool

    @Environment(\.managedObjectContext) private var viewContext
    @Environment(CurrentUser.self) private var currentUser
    @EnvironmentObject private var router: Router
    @Dependency(\.relayService) private var relayService: RelayService
    @Dependency(\.analytics) private var analytics

    @State private var refreshController = RefreshController()
    @State private var showingOptions = false
    @State private var showingReportMenu = false
    @State private var relaySubscriptions = SubscriptionCancellables()
    
    /// Keep track of the last time we downloaded Author data so we don't do it too much.
    @State private var lastDownloadedAuthorData: Date?

    @State private var selectedTab: ProfileFeedType = .notes

    @State private var alert: AlertState<Never>?
    @State private var scrollOffsetY: CGFloat = 0

    private var isShowingLoggedInUser: Bool {
        author.hexadecimalPublicKey == currentUser.publicKeyHex
    }

    init(author: Author, addDoubleTapToPop: Bool = false) {
        self.author = author
        self.addDoubleTapToPop = addDoubleTapToPop
    }

    private var databaseFilter: NSFetchRequest<Event> {
        selectedTab.databaseFilter(author: author, before: refreshController.lastRefreshDate)
    }

    private func downloadAuthorData() async {
        relaySubscriptions.removeAll()
        
        guard let authorKey = author.hexadecimalPublicKey else {
            return
        }
        
        // Profile data
        // We use our own local date for fetching contact lists and follow sets, because we want to refresh them 
        // when the page is opened, especially because a lot of contact list data gets purged during the DatabaseCleaner
        // routine, but we don't want to end up in an infinite loop like in
        // [#175](https://github.com/verse-pbc/issues/issues/175)
        relaySubscriptions.append(
            await relayService.requestProfileData(
                for: authorKey, 
                lastUpdateMetadata: author.lastUpdatedMetadata, 
                lastUpdatedContactList: lastDownloadedAuthorData, 
                lastUpdatedFollowSets: lastDownloadedAuthorData
            )
        )
        
        // reports
        let reportFilter = Filter(
            kinds: [.report],
            pTags: [authorKey],
            since: lastDownloadedAuthorData,
            keepSubscriptionOpen: true
        )
        relaySubscriptions.append(
            await relayService.fetchEvents(matching: reportFilter)
        )
        lastDownloadedAuthorData = .now
    }

    private var title: AttributedString {
        let prefix = String(localized: isShowingLoggedInUser ? "yourProfile" : "profileTitle")
        if author.muted {
            let suffix = "(\(String(localized: "muted").lowercased()))"
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
                if author.muted {
                    blockedUserListView
                } else {
                    noteListView
                }
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
            AuthorsView("follows", authors: destination.follows)
        }
        .navigationDestination(for: FollowersDestination.self) { destination in
            AuthorsView("mutualFriends", authors: destination.followers)
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
                    .confirmationDialog("share", isPresented: $showingOptions) {
                        Button("copyUserIdentifier") {
                            UIPasteboard.general.string = author.publicKey?.npub ?? ""
                        }
                        Button("copyLink") {
                            UIPasteboard.general.string = author.webLink
                        }
                        if isShowingLoggedInUser {
                            Button(
                                action: {
                                    router.push(EditProfileDestination(profile: author))
                                },
                                label: {
                                    Text("editProfile")
                                }
                            )
                            Button(
                                action: {
                                    router.push(MutesDestination())
                                },
                                label: {
                                    Text("mutedUsers")
                                }
                            )
                        } else {
                            if author.muted {
                                Button("unmuteUser") {
                                    Task {
                                        do {
                                            try await author.unmute(viewContext: viewContext)
                                        } catch {
                                            alert = AlertState(title: {
                                                TextState(String(localized: "error"))
                                            }, message: {
                                                TextState(error.localizedDescription)
                                            })
                                        }
                                    }
                                }
                            } else {
                                Button("mute") {
                                    Task { @MainActor in
                                        do {
                                            try await author.mute(viewContext: viewContext)
                                        } catch {
                                            alert = AlertState(title: {
                                                TextState(String(localized: "error"))
                                            }, message: {
                                                TextState(error.localizedDescription)
                                            })
                                        }
                                    }
                                }
                            }
                            
                            Button("flagUser") {
                                showingReportMenu = true
                            }
                        }
                    }
                }
        )
        .alert(unwrapping: $alert)
        .task {
            await downloadAuthorData()
        }
        .onChange(of: refreshController.lastRefreshDate, { _, _ in
            Task { await downloadAuthorData() }
        })
    }
    
    private var noteListView: some View {
        PagedNoteListView(
            refreshController: $refreshController,
            scrollOffsetY: .constant(0),
            databaseFilter: databaseFilter,
            relayFilter: selectedTab.relayFilter(author: author),
            relay: nil,
            managedObjectContext: viewContext,
            tab: .profile, 
            header: {
                ProfileHeader(author: author, selectedTab: $selectedTab)
                    .compositingGroup()
                    .shadow(color: .profileShadow, radius: 10, x: 0, y: 4)
            },
            emptyPlaceholder: {
                VStack {
                    Text("noEventsOnProfile")
                        .padding()
                        .readabilityPadding()
                    
                    SecondaryActionButton("tapToRefresh") {
                        refreshController.startRefresh = true
                    }
                }
                .frame(minHeight: 300)
            }
        )
        .padding(0)
        .id(selectedTab) 
    }
    
    private var blockedUserListView: some View {
        VStack {
            ProfileHeader(author: author, selectedTab: $selectedTab)
                .compositingGroup()
                .shadow(color: .profileShadow, radius: 10, x: 0, y: 4)
            Spacer()
            Text("muted")
                .padding()
                .readabilityPadding()
            Spacer()
        }
        .frame(maxHeight: .infinity)
    }
}

#Preview("Generic user") {
    var previewData = PreviewData()
    
    return NavigationStack {
        ProfileView(author: previewData.previewAuthor)
    }
    .inject(previewData: previewData)
}

#Preview("Logged in User") {
    
    @Dependency(\.persistenceController) var persistenceController 
    
    lazy var previewContext: NSManagedObjectContext = {
        persistenceController.viewContext  
    }()
    
    var previewData = PreviewData(currentUserKey: KeyFixture.eve)
    
    return NavigationStack {
        ProfileView(author: previewData.eve)
    }
    .inject(previewData: previewData)
}

#Preview("Blocked user") {
    
    @Dependency(\.persistenceController) var persistenceController 
    
    lazy var previewContext: NSManagedObjectContext = {
        persistenceController.viewContext  
    }()
    
    var previewData = PreviewData(currentUserKey: KeyFixture.eve)
    
    return NavigationStack {
        ProfileView(author: previewData.blockedUser)
    }
    .inject(previewData: previewData)
}
