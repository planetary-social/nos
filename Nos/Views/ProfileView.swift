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

typealias USBCAddress = String

struct ProfileView: View {
    
    @ObservedObject var author: Author
    
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var relayService: RelayService
    @EnvironmentObject private var currentUser: CurrentUser
    @EnvironmentObject private var router: Router
    @Dependency(\.analytics) private var analytics
    @Dependency(\.unsAPI) private var unsAPI
    
    @State private var showingOptions = false
    @State private var showingReportMenu = false
    @State private var usbcAddress: USBCAddress?
    @State private var usbcBalance: Double?
    
    @State private var subscriptionIds: [String] = []

    @State private var alert: AlertState<Never>?
    
    @FetchRequest
    private var events: FetchedResults<Event>

    @State private var unmutedEvents: [Event] = []

    private func computeUnmutedEvents() async {
        unmutedEvents = events.filter {
            if let author = $0.author {
                let notDeleted = $0.deletedOn.count == 0
                return !author.muted && notDeleted
            }
            return false
        }
    }
    
    var isShowingLoggedInUser: Bool {
        author.hexadecimalPublicKey == currentUser.publicKeyHex
    }
    
    init(author: Author) {
        self.author = author
        _events = FetchRequest(fetchRequest: author.allPostsRequest())
    }
    
    func refreshProfileFeed() async {
        // Close out stale requests
        if !subscriptionIds.isEmpty {
            await relayService.decrementSubscriptionCount(for: subscriptionIds)
            subscriptionIds.removeAll()
        }
        
        guard let authorKey = author.hexadecimalPublicKey else {
            return
        }
        
        let authors = [authorKey]
        let textFilter = Filter(authorKeys: authors, kinds: [.text, .delete, .repost, .longFormContent], limit: 50)
        async let textSub = relayService.openSubscription(with: textFilter)
        subscriptionIds.append(await textSub)
        subscriptionIds.append(
            contentsOf: await relayService.requestProfileData(
                for: authorKey, 
                lastUpdateMetadata: author.lastUpdatedMetadata, 
                lastUpdatedContactList: author.lastUpdatedContactList
            )
        )
    }
    
    func loadUSBCBalance() async {
        guard let unsName = author.uns else {
            return
        }
        do {
            usbcAddress = try await unsAPI.usbcAddress(for: unsName)
            if isShowingLoggedInUser {
                usbcBalance = try await unsAPI.usbcBalance(for: unsName)
                currentUser.usbcAddress = usbcAddress
            }
        } catch {
            Log.optional(error, "Failed to load USBC balance for \(author.hexadecimalPublicKey ?? "null")")
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical, showsIndicators: false) {
                ProfileHeader(author: author)
                    .compositingGroup()
                    .shadow(color: .profileShadow, radius: 10, x: 0, y: 4)
                
                LazyVStack {
                    if unmutedEvents.isEmpty {
                        Localized.noEventsOnProfile.view
                            .padding()
                    } else {
                        ForEach(unmutedEvents) { event in
                            VStack {
                                NoteButton(note: event, hideOutOfNetwork: false)
                                    .padding(.bottom, 15)
                            }
                        }
                    }
                }
                .padding(.top, 10)
            }
            .background(Color.appBg)
        }
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
            FollowsView(title: Localized.followedBy, authors: destination.followers)
        }
        .navigationDestination(for: RelaysDestination.self) { destination in
            RelayView(author: destination.author, editable: false)
        }
        .navigationBarItems(
            trailing:
                HStack {
                    if let usbcAddress, !isShowingLoggedInUser || usbcBalance != nil {
                        USBCBarButtonItem(address: usbcAddress, balance: $usbcBalance)
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
        .task {
            await refreshProfileFeed()
        }
        .task {
            await computeUnmutedEvents()
        }
        .task {
            await loadUSBCBalance()
        }
        .alert(unwrapping: $alert)
        .onAppear {
            Task { await loadUSBCBalance() }
            analytics.showedProfile()
        }
        .refreshable {
            await refreshProfileFeed()
            await computeUnmutedEvents()
        }
        .onChange(of: author.muted) { _ in
            Task {
                await computeUnmutedEvents()
            }
        }
        .onChange(of: author.events.count) { _ in
            Task {
                await computeUnmutedEvents()
            }
        }
        .onDisappear {
            Task(priority: .userInitiated) {
                await relayService.decrementSubscriptionCount(for: subscriptionIds)
                subscriptionIds.removeAll()
            }
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
