//
//  HomeFeedView.swift
//  Nos
//
//  Created by Matthew Lorentz on 1/31/23.
//

import SwiftUI
import CoreData
import Combine
import Dependencies

struct HomeFeedView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var relayService: RelayService
    @EnvironmentObject var router: Router
    @EnvironmentObject var currentUser: CurrentUser
    @Dependency(\.analytics) private var analytics
    @AppStorage("lastHomeFeedRequestDate") var lastRequestDateUnix: TimeInterval?
    
    @FetchRequest var events: FetchedResults<Event>
    @State private var date = Date(timeIntervalSince1970: Date.now.timeIntervalSince1970 + Double(Self.initialLoadTime))
    @State private var subscriptionIDs = [String]()
    @State private var isVisible = false
    @State private var cancellables = [AnyCancellable]()
    @State private var performingInitialLoad = true
    static let initialLoadTime = 2

    // Probably the logged in user should be in the @Environment eventually
    @ObservedObject var user: Author
    
    init(user: Author) {
        self.user = user
        self._events = FetchRequest(fetchRequest: Event.homeFeed(for: user, before: Date.now))
    }
    
    func subscribeToNewEvents() async {
        await cancelSubscriptions()
        
        let followedKeys = currentUser.socialGraph.followedKeys 
            
        guard let currentUserKey = currentUser.publicKeyHex else {
            return
        }
        
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
                
        if !followedKeys.isEmpty {
            // TODO: we could miss events with this since filter
            let textFilter = Filter(
                authorKeys: followedKeys, 
                kinds: [.text, .delete, .repost], 
                limit: 400, 
                since: nil
            )
            let textSub = await relayService.openSubscription(with: textFilter)
            subscriptionIDs.append(textSub)
        }
        
        let currentUserAuthorKeys = [currentUserKey]
        let userLikesFilter = Filter(
            authorKeys: currentUserAuthorKeys,
            kinds: [.like, .delete],
            since: fetchSinceDate
        )
        let userLikesSub = await relayService.openSubscription(with: userLikesFilter)
        subscriptionIDs.append(userLikesSub)
    }
    
    func cancelSubscriptions() async {
        if !subscriptionIDs.isEmpty {
            await relayService.removeSubscriptions(for: subscriptionIDs)
            subscriptionIDs.removeAll()
        }
    }

    var body: some View {
        NavigationStack(path: $router.homeFeedPath) {
            Group {
                if performingInitialLoad {
                    FullscreenProgressView(
                        isPresented: $performingInitialLoad, 
                        hideAfter: .now() + .seconds(Self.initialLoadTime)
                    )
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack {
                            ForEach(events) { event in
                                NoteButton(note: event, hideOutOfNetwork: false)
                                    .padding(.bottom, 15)
                            }
                        }
                        .padding(.top, 15)
                    }
                    .accessibilityIdentifier("home feed")
                }
            }
            .background(Color.appBg)
            .navigationDestination(for: Event.self) { note in
                RepliesView(note: note)
            }
            .navigationDestination(for: Author.self) { author in
                if router.currentPath.wrappedValue.count == 1 {
                    ProfileView(author: author)
                } else {
                    if author == CurrentUser.shared.author, CurrentUser.shared.editing {
                        ProfileEditView(author: author)
                    } else {
                        ProfileView(author: author)
                    }
                }
            }
            .overlay(Group {
                if events.isEmpty && !performingInitialLoad {
                    Localized.noEvents.view
                        .padding()
                }
            })
            .navigationBarItems(leading: SideMenuButton())
            .nosNavigationBar(title: .homeFeed)
        }
        .refreshable {
            date = .now
        }
        .onChange(of: date) { newDate in
            events.nsPredicate = Event.homeFeedPredicate(for: user, before: newDate)
            Task { await subscribeToNewEvents() }
        }
        .onAppear { isVisible = true }
        .onDisappear { isVisible = false }
        .onChange(of: isVisible, perform: { isVisible in
            if isVisible {
                analytics.showedHome()
                Task { await subscribeToNewEvents() }
            } else {
                Task { await cancelSubscriptions() }
            }
        })
        .task {
            currentUser.socialGraph.followedKeys.publisher
                .removeDuplicates()
                .debounce(for: 0.2, scheduler: RunLoop.main)
                .filter { _ in self.isVisible == true }
                .sink(receiveValue: { _ in
                    Task { await subscribeToNewEvents() }
                })
                .store(in: &cancellables)
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    
    static var persistenceController = PersistenceController.preview
    static var previewContext = persistenceController.container.viewContext
    static var relayService = RelayService(persistenceController: persistenceController)
    
    static var emptyPersistenceController = PersistenceController.empty
    static var emptyPreviewContext = emptyPersistenceController.container.viewContext
    static var emptyRelayService = RelayService(persistenceController: emptyPersistenceController)
    
    static var router = Router()
    
    static var currentUser: CurrentUser = {
        let currentUser = CurrentUser(persistenceController: persistenceController)
        currentUser.viewContext = previewContext
        currentUser.relayService = relayService
        Task { await currentUser.setKeyPair(KeyFixture.keyPair) }
        return currentUser
    }()
    
    static var shortNote: Event {
        let note = Event(context: previewContext)
        note.kind = 1
        note.content = "Hello, world!"
        note.author = user
        return note
    }
    
    static var longNote: Event {
        let note = Event(context: previewContext)
        note.kind = 1
        note.content = .loremIpsum(5)
        note.author = user
        return note
    }
    
    static var user: Author {
        let author = Author(context: previewContext)
        author.hexadecimalPublicKey = "d0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e"
        return author
    }
    
    static var previews: some View {
        HomeFeedView(user: user)
            .environment(\.managedObjectContext, previewContext)
            .environmentObject(relayService)
            .environmentObject(router)
            .environmentObject(currentUser)
        
        HomeFeedView(user: user)
            .environment(\.managedObjectContext, emptyPreviewContext)
            .environmentObject(emptyRelayService)
            .environmentObject(router)
    }
}
