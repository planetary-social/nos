//
//  DiscoverView.swift
//  Nos
//
//  Created by Matthew Lorentz on 2/24/23.
//

import SwiftUI
import CoreData
import Dependencies

struct DiscoverView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var relayService: RelayService
    @EnvironmentObject var router: Router
    @EnvironmentObject var currentUser: CurrentUser
    @Dependency(\.analytics) private var analytics
    @AppStorage("lastDiscoverRequestDate") var lastRequestDateUnix: TimeInterval?

    @State var showRelayPicker = false
    
    @State var relayFilter: Relay?
    
    @State var columns: Int = 0
    
    @State private var subscriptionIds = [String]()
    private var featuredAuthors: [String]
    
    @Environment(\.isSearching) private var isSearching: Bool
    @State private var searchAuthors = [Author]()
    @State var searchText = ""
    
    var predicate: NSPredicate {
        if let relayFilter {
            return Event.seen(on: relayFilter)
        } else {
            return Event.extendedNetworkPredicate(featuredAuthors: featuredAuthors)
        }
    }

    init(featuredAuthors: [String] = Array(Event.discoverTabUserIdToInfo.keys)) {
        self.featuredAuthors = featuredAuthors
    }
    
    func refreshDiscover() {
        relayService.sendCloseToAll(subscriptions: subscriptionIds)
        subscriptionIds.removeAll()
        
        if let relayFilter {
            // TODO: Use a since filter
            let singleRelayFilter = Filter(
                kinds: [.text],
                limit: 200
            )
            
            subscriptionIds.append(
                relayService.requestEventsFromAll(filter: singleRelayFilter, relays: [relayFilter])
            )
        } else {
            
            var fetchSinceDate: Date?
            /// Make sure the lastRequestDate was more than a minute ago
            /// to make sure we got all the events from it.
            if let lastRequestDateUnix {
                let lastRequestDate = Date(timeIntervalSince1970: lastRequestDateUnix)
                if lastRequestDate.distance(to: .now) > 60 {
                    fetchSinceDate = lastRequestDate
                    self.lastRequestDateUnix = Date.now.timeIntervalSince1970
                }
            } else {
                self.lastRequestDateUnix = Date.now.timeIntervalSince1970
            }
            
            let featuredFilter = Filter(
                authorKeys: featuredAuthors.compactMap {
                    PublicKey(npub: $0)?.hex
                },
                kinds: [.text],
                limit: 100,
                since: fetchSinceDate
            )
            
            subscriptionIds.append(relayService.requestEventsFromAll(filter: featuredFilter))
            
            if !currentUser.inNetworkAuthors.isEmpty {
                // this filter just requests everything for now, because I think requesting all the authors within
                // two hops is too large of a request and causes the websocket to close.
                let twoHopsFilter = Filter(
                    kinds: [.text],
                    limit: 50,
                    since: fetchSinceDate
                )
                
                subscriptionIds.append(relayService.requestEventsFromAll(filter: twoHopsFilter))
            }
        }
    }
    
    var body: some View {
        NavigationStack(path: $router.discoverPath) {
            ZStack {
                DiscoverGrid(predicate: predicate, columns: $columns)

                if showRelayPicker, let author = currentUser.author {
                    RelayPicker(
                        selectedRelay: $relayFilter,
                        defaultSelection: Localized.extendedNetwork.string,
                        author: author,
                        isPresented: $showRelayPicker
                    )
                }
            }
            .onChange(of: relayFilter) { _ in
                withAnimation {
                    showRelayPicker = false
                }
                refreshDiscover()
            }
            .searchable(text: $searchText, placement: .toolbar, prompt: PlainText(Localized.searchBar.string)) {
                ForEach(searchAuthors, id: \.self) { author in
                    Button {
                        router.push(author)
                    } label: {
                        HStack(alignment: .center) {
                            AvatarView(imageUrl: author.profilePhotoURL, size: 24)
                            Text(author.safeName)
                                .lineLimit(1)
                                .font(.subheadline)
                                .foregroundColor(Color.primaryTxt)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            if author.muted {
                                Text(Localized.mutedUser.string)
                                    .font(.subheadline)
                                    .foregroundColor(Color.secondaryTxt)
                            }
                            Spacer()
                            if let currentUser = CurrentUser.shared.author {
                                FollowButton(currentUserAuthor: currentUser, author: author)
                                    .padding(10)
                            }
                        }.searchCompletion(author.safeName)
                    }
                }
            }
            .autocorrectionDisabled()
            .onSubmit(of: .search) {
                submitSearch()
            }
            .onChange(of: searchText) { _ in
                if searchText.isEmpty && !isSearching {
                    searchAuthors = []
                } else {
                    submitSearch()
                }
            }
            .background(Color.appBg)
            .toolbar {
                RelayPickerToolbarButton(
                    selectedRelay: $relayFilter,
                    isPresenting: $showRelayPicker,
                    defaultSelection: Localized.extendedNetwork
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
            .refreshable {
                refreshDiscover()
            }
            .onAppear {
                if router.selectedTab == .discover {
                    searchText = ""
                    searchAuthors = []
                    analytics.showedDiscover()
                    refreshDiscover()
                }
            }
            .onDisappear {
                searchAuthors = []
                
                relayService.sendCloseToAll(subscriptions: subscriptionIds)
                subscriptionIds.removeAll()
            }
            .navigationDestination(for: Event.self) { note in
                RepliesView(note: note)
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
    
    func author(from publicKeyString: String) -> Author? {
        guard let publicKey = PublicKey(npub: publicKeyString) ?? PublicKey(hex: publicKeyString) else {
            return nil
        }
        guard let author = try? Author.findOrCreate(by: publicKey.hex, context: viewContext) else {
            return nil
        }
        return author
    }
    
    func authors(named name: String) -> [Author] {
        guard let authors = try? Author.find(named: name, context: viewContext) else {
            return []
        }

        return authors
    }
    
    func submitSearch() {
        if searchText.contains("@") {
            Task {
                if let publicKeyHex =
                    await relayService.retrieveInternetIdentifierPublicKeyHex(searchText.lowercased()),
                    let author = author(from: publicKeyHex) {
                    searchAuthors = [author]
                    router.push(author)
                }
            }
        } else {
            if let author = author(from: searchText) {
                searchAuthors = [author]
                router.push(author)
            } else {
                searchAuthors = authors(named: searchText)
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
    
    static var persistenceController = PersistenceController.preview
    static var previewContext = persistenceController.container.viewContext
    static var relayService = RelayService(persistenceController: persistenceController)
    
    static var emptyPersistenceController = PersistenceController.empty
    static var emptyPreviewContext = emptyPersistenceController.container.viewContext
    static var emptyRelayService = RelayService(persistenceController: emptyPersistenceController)
    static var currentUser: CurrentUser = {
        let currentUser = CurrentUser()
        currentUser.privateKeyHex = KeyFixture.alice.privateKeyHex
        currentUser.context = previewContext
        currentUser.relayService = relayService
        return currentUser
    }()
    
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
        
        try! previewContext.save()
    }
    
    static func createRelayData(in context: NSManagedObjectContext, user: Author) {
        let addresses = ["wss://nostr.band", "wss://nos.social", "wss://a.long.domain.name.to.see.what.happens"]
        addresses.forEach {
            _ = try! Relay(context: previewContext, address: $0, author: user)
        }
        
        try! previewContext.save()
    }
    
    @State static var relayFilter: Relay?
    
    static var previews: some View {
        DiscoverView(featuredAuthors: [user.publicKey!.npub])
            .environment(\.managedObjectContext, previewContext)
            .environmentObject(relayService)
            .environmentObject(router)
            .environmentObject(currentUser)
            .onAppear { createTestData(in: previewContext) }
        
        DiscoverView(featuredAuthors: [user.publicKey!.npub])
            .environment(\.managedObjectContext, previewContext)
            .environmentObject(relayService)
            .environmentObject(router)
            .environmentObject(currentUser)
            .onAppear { createTestData(in: previewContext) }
            .previewDevice("iPad Air (5th generation)")
    }
}

struct RelayPickerToolbarButton: ToolbarContent {
    
    @Binding var selectedRelay: Relay?
    @Binding var isPresenting: Bool
    var defaultSelection: Localized
    var action: () -> Void
    
    var title: String {
        if let selectedRelay {
            return selectedRelay.host ?? Localized.error.string
        } else {
            return defaultSelection.string
        }
    }
    
    var imageName: String {
        if isPresenting {
            return "chevron.up"
        } else {
            return "chevron.down"
        }
    }
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Button {
                action()
            } label: {
                HStack {
                    PlainText(title)
                        .font(.clarityTitle3)
                        .foregroundColor(.primaryTxt)
                        .bold()
                        .padding(.leading, 14)
                    Image(systemName: imageName)
                        .font(.system(size: 10))
                        .bold()
                        .foregroundColor(.secondary)
                }
            }
            .frame(height: 35)
            .background(
                Color.appBg
                    .cornerRadius(20)
            )
            .padding(.bottom, 3)
        }
    }
}
