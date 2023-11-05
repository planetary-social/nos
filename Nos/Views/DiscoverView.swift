//
//  DiscoverView.swift
//  Nos
//
//  Created by Matthew Lorentz on 2/24/23.
//

import SwiftUI
import Combine
import CoreData
import Dependencies

struct DiscoverView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var relayService: RelayService
    @Environment(Router.self) var router
    @Environment(CurrentUser.self) var currentUser
    @Dependency(\.analytics) private var analytics
    @State private var lastRequestDate: Date?

    @State var showRelayPicker = false
    
    @State var relayFilter: Relay?
    
    @State var columns: Int = 0
    
    @State private var performingInitialLoad = true
    static let initialLoadTime = 2
    @State private var subscriptionIDs = [String]()
    @State private var isVisible = false
    private var featuredAuthors: [String]
    
    @StateObject private var searchController = SearchController()
    @State private var date = Date(timeIntervalSince1970: Date.now.timeIntervalSince1970 + Double(Self.initialLoadTime))

    @State var predicate: NSPredicate = .false
    
    func updatePredicate() {
        if let relayFilter {
            predicate = Event.seen(on: relayFilter, before: date, exceptFrom: currentUser.author)
        } else {
            predicate = Event.extendedNetworkPredicate(
                currentUser: currentUser, 
                featuredAuthors: featuredAuthors, 
                before: date
            )
        }
    }

    init(featuredAuthors: [String] = Array(Event.discoverTabUserIdToInfo.keys)) {
        self.featuredAuthors = featuredAuthors
    }
    
    func subscribeToNewEvents() async {
        await cancelSubscriptions()
        
        if let relayAddress = relayFilter?.addressURL {
            // TODO: Use a since filter
            let singleRelayFilter = Filter(
                kinds: [.text, .delete],
                limit: 100
            )
            
            subscriptionIDs.append(
                // TODO: I don't think the override relays will be honored when opening new sockets
                await relayService.openSubscription(with: singleRelayFilter, to: [relayAddress])
            )
        } else {
            
            var fetchSinceDate: Date?
            // Make sure the lastRequestDate was more than a minute ago
            // to make sure we got all the events from it.
            if let lastRequestDate {
                if lastRequestDate.distance(to: .now) > 60 {
                    fetchSinceDate = lastRequestDate
                    self.lastRequestDate = Date.now
                }
            } else {
                self.lastRequestDate = Date.now
            }
            
            let featuredFilter = Filter(
                authorKeys: featuredAuthors.compactMap {
                    PublicKey(npub: $0)?.hex
                },
                kinds: [.text, .delete],
                limit: 50,
                since: fetchSinceDate
            )
            
            subscriptionIDs.append(await relayService.openSubscription(with: featuredFilter))
            
            // this filter just requests everything for now, because I think requesting all the authors within
            // two hops is too large of a request and causes the websocket to close.
            let twoHopsFilter = Filter(
                kinds: Event.discoverKinds,
                inNetwork: true,
                limit: 200,
                since: fetchSinceDate
            )
            
            subscriptionIDs.append(await relayService.openSubscription(with: twoHopsFilter))
        }
    }
    
    func cancelSubscriptions() async {
        if !subscriptionIDs.isEmpty {
            await relayService.decrementSubscriptionCount(for: subscriptionIDs)
            subscriptionIDs.removeAll()
        }
    }
    
    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.discoverPath) {
            ZStack {
                if performingInitialLoad {
                    FullscreenProgressView(
                        isPresented: $performingInitialLoad, 
                        hideAfter: .now() + .seconds(Self.initialLoadTime)
                    )
                } else {
                    DiscoverGrid(predicate: predicate, searchController: searchController, columns: $columns)
                    
                    if showRelayPicker, let author = currentUser.author {
                        RelayPicker(
                            selectedRelay: $relayFilter,
                            defaultSelection: Localized.allMyRelays.string,
                            author: author,
                            isPresented: $showRelayPicker
                        )
                    }
                }
            }
            .searchable(
                text: $searchController.query, 
                placement: .toolbar, 
                prompt: PlainText(Localized.searchBar.string)
            )
            .autocorrectionDisabled()
            .onSubmit(of: .search) {
                submitSearch()
            }
            .background(Color.appBg)
            .toolbar {
                RelayPickerToolbarButton(
                    selectedRelay: $relayFilter,
                    isPresenting: $showRelayPicker,
                    defaultSelection: Localized.allMyRelays
                ) {
                    withAnimation {
                        showRelayPicker.toggle()
                    }
                }
                ToolbarItem {
                    HStack {
                        Button {
                            columns = max(columns - 1, 1)
                        } label: {
                            Image(systemName: "minus")
                        }
                        Button {
                            columns += 1
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .animation(.easeInOut, value: columns)
            .doubleTapToPop(tab: .discover)
            .task { 
                updatePredicate()
            }
            .refreshable {
                date = .now
            }
            .onChange(of: relayFilter) { _ in
                withAnimation {
                    showRelayPicker = false
                }
                updatePredicate()
                Task { await subscribeToNewEvents() }
            }
            .onChange(of: date) { _ in
                updatePredicate()
            }
            .refreshable {
                date = .now
            }
            .onAppear {
                if router.selectedTab == .discover {
                    isVisible = true
                }
            }
            .onDisappear {
                isVisible = false
            }
            .onChange(of: isVisible, perform: { isVisible in
                if isVisible {
                    analytics.showedDiscover()
                    Task { await subscribeToNewEvents() }
                } else {
                    Task { await cancelSubscriptions() }
                }
            })
            .navigationDestination(for: Event.self) { note in
                RepliesView(note: note)
            }
            .navigationDestination(for: URL.self) { url in URLView(url: url) }
            .navigationDestination(for: ReplyToNavigationDestination.self) { destination in 
                RepliesView(note: destination.note, showKeyboard: true)
            }
            .navigationDestination(for: Author.self) { author in
                ProfileView(author: author)
            }
            .navigationBarTitle(Localized.discover.string, displayMode: .inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.cardBgBottom, for: .navigationBar)
            .navigationBarItems(leading: SideMenuButton())
        }
    }
    
    func author(fromPublicKey publicKeyString: String) -> Author? {
        let strippedString = publicKeyString.trimmingCharacters(
            in: NSCharacterSet.whitespacesAndNewlines
        )
        guard let publicKey = PublicKey(npub: strippedString) ?? PublicKey(hex: strippedString) else {
            return nil
        }
        guard let author = try? Author.findOrCreate(by: publicKey.hex, context: viewContext) else {
            return nil
        }
        try? viewContext.saveIfNeeded()
        return author
    }
    
    func submitSearch() {
        if searchController.query.contains("@") {
            Task(priority: .userInitiated) {
                if let publicKeyHex =
                    await relayService.retrievePublicKeyFromUsername(searchController.query.lowercased()),
                    let author = author(fromPublicKey: publicKeyHex) {
                    router.push(author)
                }
            }
        } else {
            if let author = author(fromPublicKey: searchController.query) {
                router.push(author)
            }
        }
    }
}

struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

struct DiscoverView_Previews: PreviewProvider {
    
    static var previewData = PreviewData()
    static var persistenceController = PersistenceController.preview
    static var previewContext = persistenceController.container.viewContext
    static var relayService = previewData.relayService
    
    static var emptyPersistenceController = PersistenceController.empty
    static var emptyPreviewContext = emptyPersistenceController.container.viewContext
    static var emptyRelayService = previewData.relayService
    static var currentUser = previewData.currentUser
    static var router = Router()
    
    static var user: Author {
        let author = Author(context: previewContext)
        author.hexadecimalPublicKey = KeyFixture.alice.publicKeyHex
        return author
    }
    
    static func createTestData(in context: NSManagedObjectContext) {
        let shortNote = Event(context: previewContext)
        shortNote.identifier = "1"
        shortNote.author = user
        shortNote.content = "Hello, world!"
        
        let longNote = Event(context: previewContext)
        longNote.identifier = "2"
        longNote.author = user
        longNote.content = .loremIpsum(5)

        try? previewContext.save()
    }
    
    static func createRelayData(in context: NSManagedObjectContext, user: Author) {
        let addresses = ["wss://nostr.band", "wss://nos.social", "wss://a.long.domain.name.to.see.what.happens"]
        addresses.forEach {
            _ = try? Relay(context: previewContext, address: $0, author: user)
        }

        try? previewContext.save()
    }
    
    @State static var relayFilter: Relay?
    
    static var previews: some View {
        if let publicKey = user.publicKey {
            DiscoverView(featuredAuthors: [publicKey.npub])
                .environment(\.managedObjectContext, previewContext)
                .environmentObject(relayService)
                .environment(router)
                .environment(currentUser)
                .onAppear { createTestData(in: previewContext) }

            DiscoverView(featuredAuthors: [publicKey.npub])
                .environment(\.managedObjectContext, previewContext)
                .environmentObject(relayService)
                .environment(router)
                .environment(currentUser)
                .onAppear { createTestData(in: previewContext) }
                .previewDevice("iPad Air (5th generation)")
        } else {
            EmptyView()
        }
    }
}
