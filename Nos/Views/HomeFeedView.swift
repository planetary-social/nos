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
    
    @FetchRequest var events: FetchedResults<Event>
    @State private var date = Date(timeIntervalSince1970: Date.now.timeIntervalSince1970 + Double(Self.initialLoadTime))
    @State private var subscriptionIDs = [String]()
    @State private var isVisible = false
    @State private var cancellables = [AnyCancellable]()
    @State private var performingInitialLoad = true
    @State private var numberOfConnectedRelays = 0
    @State private var isShowingRelayList = false
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
            
        if !followedKeys.isEmpty {
            // TODO: we could miss events with this since filter
            let textFilter = Filter(
                authorKeys: followedKeys, 
                kinds: [.text, .delete, .repost, .longFormContent], 
                limit: 400, 
                since: nil
            )
            let textSub = await relayService.openSubscription(with: textFilter)
            subscriptionIDs.append(textSub)
        }
    }
    
    func cancelSubscriptions() async {
        if !subscriptionIDs.isEmpty {
            await relayService.decrementSubscriptionCount(for: subscriptionIDs)
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
                        .padding(.vertical, 15)
                    }
                    .accessibilityIdentifier("home feed")
                }
            }
            .background(Color.appBg)
            .navigationDestination(for: Event.self) { note in
                RepliesView(note: note)
            }
            .navigationDestination(for: URL.self) { url in
                URLView(url: url)
            }
            .navigationDestination(for: ReplyToNavigationDestination.self) { destination in 
                RepliesView(note: destination.note, showKeyboard: true)
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
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    SideMenuButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isShowingRelayList = true
                    } label: {
                        HStack(spacing: 3) {
                            Image("relay-left")
                                .colorMultiply(numberOfConnectedRelays > 0 ? .white : .red)
                            Text("\(numberOfConnectedRelays)")
                                .font(.clarityTitle3)
                                .fontWeight(.heavy)
                                .foregroundColor(.primaryTxt)
                            Image("relay-right")
                                .colorMultiply(numberOfConnectedRelays > 0 ? .white : .red)
                        }
                    }
                    .sheet(isPresented: $isShowingRelayList) {
                        NavigationView {
                            RelayView(author: user)
                        }
                    }
                }
            }
            .nosNavigationBar(title: .homeFeed)
        }
        .onChange(of: relayService.numberOfConnectedRelays) { newValue in
            numberOfConnectedRelays = newValue
        }
        .refreshable {
            date = .now
        }
        .onChange(of: date) { newDate in
            events.nsPredicate = Event.homeFeedPredicate(for: user, before: newDate)
            Task { await subscribeToNewEvents() }
        }
        .onAppear { 
            if router.selectedTab == .home {
                isVisible = true 
            }
        }
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
