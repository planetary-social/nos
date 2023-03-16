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

    private var eventRequest: FetchRequest<Event> = FetchRequest(fetchRequest: Event.emptyRequest())

    private var events: FetchedResults<Event> { eventRequest.wrappedValue }
    
    @State var columns: Int = 0
    
    @State private var gridSize: CGSize = .zero {
        didSet {
            // Initialize columns based on width of the grid
            if columns == 0, gridSize.width > 0 {
                columns = Int(floor(gridSize.width / 172))
            }
        }
    }
    
    @Namespace private var animation
    
    @State private var subscriptionIds = [String]()
    private var authors: [String]
    
    @State var searchText = "" {
        didSet {
            if let publicKey = PublicKey(npub: searchText) {
                let author = try! Author.findOrCreate(by: publicKey.hex, context: viewContext)
                router.push(author)
            } else if let publicKey = PublicKey(hex: searchText) {
                let author = try! Author.findOrCreate(by: publicKey.hex, context: viewContext)
                router.push(author)
            }
        }
    }
    
    init(authors: [String] = Array(Event.discoverTabUserIdToInfo.keys)) {
        self.authors = authors
        eventRequest = FetchRequest(fetchRequest: Event.discoverFeedRequest(authors: authors))
    }
    
    func refreshDiscover() {
        // TODO: Look into why subscriptions aren't being closed when we leave the discover tab
        relayService.sendCloseToAll(subscriptions: subscriptionIds)
        subscriptionIds.removeAll()
        
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
            authorKeys: authors.compactMap {
                PublicKey(npub: $0)?.hex
            },
            kinds: [.text],
            limit: 100,
            since: fetchSinceDate
        )
        
        subscriptionIds.append(relayService.requestEventsFromAll(filter: featuredFilter))
        
        if !currentUser.inNetworkAuthors.isEmpty {
            // this filter just requests everything for now, because I think requesting all the authors within two
            // hops is too large of a request and causes the websocket to close.
            let twoHopsFilter = Filter(
                kinds: [.text],
                limit: 200,
                since: fetchSinceDate
            )
            
            subscriptionIds.append(relayService.requestEventsFromAll(filter: twoHopsFilter))
        }
        
        // TODO: update fetch request because follow graph might have changed
        // eventRequest = FetchRequest(fetchRequest: Event.discoverFeedRequest(authors: authors))
    }
    
    var body: some View {
        NavigationStack(path: $router.discoverPath) {
            GeometryReader { geometry in
                StaggeredGrid(list: events, columns: columns) { note in
                    NoteButton(note: note, style: .golden)
                        .matchedGeometryEffect(id: note.identifier, in: animation)
                }
                .preference(key: SizePreferenceKey.self, value: geometry.size)
            }
            .onPreferenceChange(SizePreferenceKey.self) { preference in
                gridSize = preference
            }
            .searchable(text: $searchText, placement: .toolbar, prompt: PlainText("Find a user by ID or NIP-05"))
            .autocorrectionDisabled()
            .onSubmit(of: .search) {
                
                if let author = author(from: searchText) {
                    router.push(author)
                } else {
                    if searchText.contains("@") {
                        Task {
                            if let publicKeyHex =
                                await relayService.retrieveInternetIdentifierPublicKeyHex(searchText.lowercased()),
                            let author = author(from: publicKeyHex) {
                                router.push(author)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
            .background(Color.appBg)
            .toolbar {
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
            .task {
                refreshDiscover()
            }
            .onAppear {
                analytics.showedDiscover()
            }
            .onDisappear {
                // TODO: Look into why subscriptions aren't being closed when we leave the discover tab
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
            .navigationBarItems(
                leading: Button(
                    action: {
                        router.toggleSideMenu()
                    },
                    label: {
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(.nosSecondary)
                    }
                )
            )
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
    
    static var router = Router()
    
    static var user: Author {
        let author = Author(context: previewContext)
        author.hexadecimalPublicKey = "d0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e"
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
    
    static var previews: some View {
        DiscoverView(authors: [user.publicKey!.npub])
            .environment(\.managedObjectContext, previewContext)
            .environmentObject(relayService)
            .environmentObject(router)
            .onAppear { createTestData(in: previewContext) }
        
        DiscoverView(authors: [user.publicKey!.npub])
            .environment(\.managedObjectContext, previewContext)
            .environmentObject(relayService)
            .environmentObject(router)
            .onAppear { createTestData(in: previewContext) }
            .previewDevice("iPad Air (5th generation)")
    }
}
