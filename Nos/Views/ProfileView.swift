//
//  ProfileView.swift
//  Nos
//
//  Created by Matthew Lorentz on 2/16/23.
//

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

    @State private var alert: AlertState<Never>?
    
    @FetchRequest
    private var events: FetchedResults<Event>

    var isShowingLoggedInUser: Bool {
        author.hexadecimalPublicKey == currentUser.publicKeyHex
    }
    
    init(author: Author, addDoubleTapToPop: Bool = false) {
        self.author = author
        self.addDoubleTapToPop = addDoubleTapToPop
        _events = FetchRequest(fetchRequest: author.allPostsRequest())
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
                    databaseFilter: author.allPostsRequest(), 
                    relayFilter: profileNotesFilter,
                    context: viewContext,
                    header: {
                        ProfileHeader(author: author)
                            .compositingGroup()
                            .shadow(color: .profileShadow, radius: 10, x: 0, y: 4)
                            .id(author.id)
                    },
                    emptyPlaceholder: {
                        VStack {
                            Localized.noEventsOnProfile.view
                                .padding()
                                .readabilityPadding()
                        }
                        .frame(minHeight: 300)
                    },
                    onRefresh: {
                        author.allPostsRequest(since: .now)
                    }
                )
                .padding(0)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .id(author.id)
            .doubleTapToPop(tab: .profile, enabled: addDoubleTapToPop) { proxy in
                proxy.scrollTo(author.id)
            }
        }
        .background(Color.appBg)
        .nosNavigationBar(title: .profileTitle)
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
            FollowsView(title: Localized.follows, authors: destination.follows)
        }
        .navigationDestination(for: FollowersDestination.self) { destination in
            FollowsView(title: Localized.followers, authors: destination.followers)
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
                    .confirmationDialog(Localized.share.string, isPresented: $showingOptions) {
                        Button(Localized.copyUserIdentifier.string) {
                            UIPasteboard.general.string = author.publicKey?.npub ?? ""
                        }
                        Button(Localized.copyLink.string) {
                            UIPasteboard.general.string = author.webLink 
                        }
                        if isShowingLoggedInUser {
                            Button(
                                action: {
                                    currentUser.editing = true
                                    router.push(author)
                                },
                                label: {
                                    Text(Localized.editProfile.string)
                                }
                            )
                            Button(
                                action: {
                                    router.push(MutesDestination())
                                },
                                label: {
                                    Text(Localized.mutedUsers.string)
                                }
                            )
                        } else {
                            if author.muted {
                                Button(Localized.unmuteUser.string) {
                                    Task {
                                        do {
                                            try await author.unmute(viewContext: viewContext)
                                        } catch {
                                            alert = AlertState(title: {
                                                TextState(Localized.error.string)
                                            }, message: {
                                                TextState(error.localizedDescription)
                                            })
                                        }
                                    }
                                }
                            } else {
                                Button(Localized.mute.string) {
                                    Task { @MainActor in
                                        do {
                                            try await author.mute(viewContext: viewContext)
                                        } catch {
                                            alert = AlertState(title: {
                                                TextState(Localized.error.string)
                                            }, message: {
                                                TextState(error.localizedDescription)
                                            })
                                        }
                                    }
                                }
                            }
                            
                            Button(Localized.reportUser.string, role: .destructive) {
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
