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
    @Environment(Router.self) var router
    @Environment(CurrentUser.self) var currentUser
    @Dependency(\.analytics) private var analytics
    
    @FetchRequest var events: FetchedResults<Event>
    @FetchRequest private var authors: FetchedResults<Author>
    
    @State private var date = Date(timeIntervalSince1970: Date.now.timeIntervalSince1970 + Double(Self.initialLoadTime))
    @State private var subscriptionIDs = [String]()
    @State private var isVisible = false
    @State private var cancellables = [AnyCancellable]()
    @State private var performingInitialLoad = true
    @State private var isShowingRelayList = false
    static let initialLoadTime = 2

    @ObservedObject var user: Author

    @State private var selectedStoryAuthor: Author?
    @State private var storiesCutoffDate = Calendar.current.date(byAdding: .day, value: -2, to: .now)!

    private var isShowingStories: Bool {
        selectedStoryAuthor != nil
    }
    
    init(user: Author) {
        self.user = user
        _events = FetchRequest(fetchRequest: Event.homeFeed(for: user, before: Date.now))
        _authors = FetchRequest(
            fetchRequest: user.followedWithNewNotes(
                since: Calendar.current.date(byAdding: .day, value: -2, to: .now)!
            )
        )
    }
    
    func subscribeToNewEvents() async {
        await cancelSubscriptions()
        
        let followedKeys = currentUser.socialGraph.followedKeys 
            
        if !followedKeys.isEmpty {
            // TODO: we could miss events with this since filter
            let textFilter = Filter(
                authorKeys: followedKeys, 
                kinds: [.text, .delete, .repost, .longFormContent, .report], 
                limit: 100, 
                since: nil
            )
            let textSubs = await relayService.openSubscriptions(with: textFilter)
            subscriptionIDs.append(contentsOf: textSubs)
        }
    }
    
    func cancelSubscriptions() async {
        if !subscriptionIDs.isEmpty {
            await relayService.decrementSubscriptionCount(for: subscriptionIDs)
            subscriptionIDs.removeAll()
        }
    }

    var body: some View {
        Group {
            if performingInitialLoad {
                FullscreenProgressView(
                    isPresented: $performingInitialLoad,
                    hideAfter: .now() + .seconds(Self.initialLoadTime)
                )
            } else {
                ZStack {
                    ScrollView(.vertical, showsIndicators: false) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(authors) { author in
                                    Button {
                                        withAnimation {
                                            selectedStoryAuthor = author
                                        }
                                    } label: {
                                        AvatarView(imageUrl: author.profilePhotoURL, size: 54)
                                            .padding(.vertical, 10)
                                            .background(
                                                Circle()
                                                    .stroke(LinearGradient.diagonalAccent, lineWidth: 3)
                                                    .frame(width: 58, height: 58)
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal, 15)
                        }
                        .padding(.top, 15)
                        .readabilityPadding()
                        LazyVStack {
                            ForEach(events) { event in
                                NoteButton(note: event, hideOutOfNetwork: false)
                                    .padding(.bottom, 15)
                            }
                        }
                        .padding(.vertical, 15)
                    }
                    .accessibilityIdentifier("home feed")

                    StoriesView(
                        cutoffDate: $storiesCutoffDate,
                        authors: authors,
                        selectedAuthor: $selectedStoryAuthor
                    )
                    .scaleEffect(isShowingStories ? 1 : 0.5)
                    .opacity(isShowingStories ? 1 : 0)
                    .animation(.default, value: selectedStoryAuthor)
                }
            }
        }
        .background(Color.appBg)
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
                if isShowingStories {
                    Button {
                        selectedStoryAuthor = nil
                    } label: {
                        Image.stories.rotationEffect(selectedStoryAuthor == nil ? Angle.zero : Angle(degrees: 90))
                            .animation(.default, value: selectedStoryAuthor)
                    }
                } else {
                    Button {
                        isShowingRelayList = true
                    } label: {
                        HStack(spacing: 3) {
                            Image("relay-left")
                                .colorMultiply(relayService.numberOfConnectedRelays > 0 ? .white : .red)
                            Text("\(relayService.numberOfConnectedRelays)")
                                .font(.clarityTitle3)
                                .fontWeight(.heavy)
                                .foregroundColor(.primaryTxt)
                            Image("relay-right")
                                .colorMultiply(relayService.numberOfConnectedRelays > 0 ? .white : .red)
                        }
                    }
                    .sheet(isPresented: $isShowingRelayList) {
                        NavigationView {
                            RelayView(author: user)
                        }
                    }
                }
            }
        }
        .background(Color.appBg)
        .padding(.top, 1)
        .overlay(Group {
            if !events.contains(where: { !$0.author!.muted }) {
                Localized.noEvents.view
                    .padding()
            }
        })
        .nosNavigationBar(title: isShowingStories ? Localized.stories : Localized.homeFeed)
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
        .doubleTapToPop(tab: .home) {
            if isShowingStories {
                selectedStoryAuthor = nil
            }
        }
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
    
    static var previewData = PreviewData()
    static var persistenceController = PersistenceController.preview
    static var previewContext = persistenceController.container.viewContext
    static var relayService = previewData.relayService
    
    static var emptyPersistenceController = PersistenceController.empty
    static var emptyPreviewContext = emptyPersistenceController.container.viewContext
    static var emptyRelayService = previewData.relayService
    
    static var router = Router()
    
    static var currentUser = previewData.currentUser
    
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
            .environment(router)
            .environment(currentUser)
        
        HomeFeedView(user: user)
            .environment(\.managedObjectContext, emptyPreviewContext)
            .environmentObject(emptyRelayService)
            .environment(router)
    }
}
