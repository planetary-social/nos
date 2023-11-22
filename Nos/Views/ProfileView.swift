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
import Algorithms

@MainActor @Observable class ProfileController: NSObject, NSFetchedResultsControllerDelegate {

    var lastRefreshDate = Date()
    var notes = [[Event]]()
    let pageSize = 10
    var page = 0
    var isLoadingMore = false
        
    var author: Author? {
        didSet { 
            if oldValue != author {
                refresh()
            }
        }
    }
    
    var context: NSManagedObjectContext? {
        didSet { 
            if oldValue != context {
                refresh()
            }
        }
    }
    
    @Dependency(\.persistenceController) @ObservationIgnored private var persistenceController
    @Dependency(\.relayService) @ObservationIgnored private var relayService
    private var fetchRequest: NSFetchRequest<Event>?
    private var subscriptionIDs: [RelaySubscription.ID] = []
    private var relatedEventSubscriptions: [RelaySubscription.ID] = []
    private var fetchedResultsController: NSFetchedResultsController<Event>?
    
    func refresh() {
        guard let author, let context else {
            return
        }
        
        isLoadingMore = true
        lastRefreshDate = .now
        page = 0
        let fetchRequest = author.allPostsRequest(since: lastRefreshDate)
        fetchRequest.fetchOffset = 0
        fetchRequest.fetchLimit = pageSize
        self.fetchRequest = fetchRequest
        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest, 
            managedObjectContext: context, 
            sectionNameKeyPath: nil, 
            cacheName: "ProfileController"
        )
//        fetchedResultsController?.delegate = self
//        try! fetchedResultsController?.performFetch()
        
        Task {
            await subscribe()
            let noteIDs = await context.perform {
                let newNotes = try! context.fetch(fetchRequest)
                self.notes = [newNotes]
                return newNotes.compactMap { $0.identifier }
            }
            await subscribeToEvents(relatedTo: noteIDs)
            isLoadingMore = false
        }
    }
    
    func subscribe() async {
        // Close out stale requests
        if !subscriptionIDs.isEmpty {
            await relayService.decrementSubscriptionCount(for: subscriptionIDs)
            subscriptionIDs.removeAll()
            await relayService.decrementSubscriptionCount(for: relatedEventSubscriptions)
            relatedEventSubscriptions.removeAll()
        }
        
        guard let author, let authorKey = author.hexadecimalPublicKey else {
            return
        }
        
        let authors = [authorKey]
        let textFilter = Filter(authorKeys: authors, kinds: [.text, .delete, .repost, .longFormContent], limit: 50)
        async let textSubs = relayService.openSubscriptions(with: textFilter)
        subscriptionIDs += await textSubs
        subscriptionIDs.append(
            contentsOf: await relayService.requestProfileData(
                for: authorKey, 
                lastUpdateMetadata: author.lastUpdatedMetadata, 
                lastUpdatedContactList: nil
            )
        )
        
        // reports
        let reportFilter = Filter(kinds: [.report], pTags: [authorKey])
        subscriptionIDs += await relayService.openSubscriptions(with: reportFilter)
    }
    
    func subscribeToEvents(relatedTo eventIDs: [HexadecimalString]) async {
        let filter = Filter(kinds: [.text, .like, .delete, .repost, .report], eTags: eventIDs)
        let subIDs = await relayService.openSubscriptions(with: filter)
        subscriptionIDs.append(contentsOf: subIDs)
        // TODO: cancel these
        // TODO: observation
    }
    
    func loadMore() async {
        guard !isLoadingMore, let fetchRequest, let context else {
            return
        }
        
        isLoadingMore = true
        page += 1
        fetchRequest.fetchOffset = page * pageSize
        let noteIDs = await context.perform {
            let newNotes = try! context.fetch(fetchRequest)
            self.notes[0].append(contentsOf: newNotes)
            return newNotes.compactMap { $0.identifier }
        }
        await subscribeToEvents(relatedTo: noteIDs)
        self.isLoadingMore = false
    }
    
    func onDisappear() {
        Task(priority: .userInitiated) {
            await relayService.decrementSubscriptionCount(for: subscriptionIDs)
            subscriptionIDs.removeAll()
        }
    }
    
    nonisolated func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, 
                    didChange anObject: Any, 
                    at indexPath: IndexPath?, 
                    for type: NSFetchedResultsChangeType, 
                    newIndexPath: IndexPath?) {
        
        guard let anObject = anObject as? Event else { return }
        
        Task { @MainActor in 
            switch type {
            case .insert:
                if let newIndexPath = newIndexPath {
                    notes[0].insert(anObject, at: newIndexPath.row)
                }
            case .delete:
                if let indexPath = indexPath {
                    notes[0].remove(at: indexPath.row)
                }
            case .update:
                if let indexPath = indexPath {
                    notes[0][indexPath.row] = anObject
                }
            case .move:
                if let indexPath = indexPath, let newIndexPath = newIndexPath {
                    let movedObject = notes[0].remove(at: indexPath.row)
                    notes[0].insert(movedObject, at: newIndexPath.row)
                }
            @unknown default:
                fatalError("NSFetchedResultsControllerChangeType case not handled.")
            }
        }
    }
}

struct ProfileView: View {
    
    @ObservedObject var author: Author
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(CurrentUser.self) private var currentUser
    @Environment(Router.self) private var router
    @Dependency(\.analytics) private var analytics
    @Dependency(\.unsAPI) private var unsAPI
    
    @State private var controller = ProfileController()
    @State private var showingOptions = false
    @State private var showingReportMenu = false
    @State private var usbcAddress: USBCAddress?
    @State private var usbcBalance: Double?
    @State private var usbcBalanceTimer: Timer?
    

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
        controller.refresh()
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
    
    var body: some View {
        VStack(spacing: 0) {
                ProfileHeader(author: author)
                    .compositingGroup()
                    .shadow(color: .profileShadow, radius: 10, x: 0, y: 4)
                
                VStack {
                    if unmutedEvents.isEmpty {
                        Localized.noEventsOnProfile.view
                            .padding()
                    } else {
                        NoteList(fetchRequest: author.allPostsRequest(), context: viewContext)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
//                        ForEach(controller.notes, id: \.self) { page in
//                            VStack {
//                                ForEach(page) { note in 
//                                    NoteButton(note: note, hideOutOfNetwork: false, displayRootMessage: true)
//                                        .padding(.bottom, 15)
//                                }
//                            }
//                            .onAppear {
//                                if controller.notes.last == page {
//                                    Task { await controller.loadMore() }
//                                }
//                            }
//                        }
//                        if controller.isLoadingMore {
//                            ProgressView()
//                        }
                    }
                    Spacer()
                }
                .padding(.top, 10)
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
        .task {
            controller.context = viewContext
            controller.author = author 
        }
        .task {
            await computeUnmutedEvents()
        }
        .onChange(of: author.uns) { _ in
            Task {
                await loadUSBCBalance()
            }
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
            controller.onDisappear()
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
