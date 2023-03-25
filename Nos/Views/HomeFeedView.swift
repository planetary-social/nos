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
    @FetchRequest var followedAuthors: FetchedResults<Author>

    @ObservedObject var user: Author
    
    @State private var subscriptionIds: [String] = []
    
    init(user: Author) {
        self.user = user
        self._events = FetchRequest(fetchRequest: Event.homeFeed(for: user))
        self._followedAuthors = FetchRequest(fetchRequest: user.followsRequest())
    }

    func refreshHomeFeed() {
        // Close out stale requests
        if !subscriptionIds.isEmpty {
            relayService.sendCloseToAll(subscriptions: subscriptionIds)
            subscriptionIds.removeAll()
        }
        
        // I can't figure out why but the home feed doesn't update when you follow someone without this.
        if let currentUserKey = currentUser.author?.hexadecimalPublicKey {
            // swiftlint:disable line_length
            events.nsPredicate = NSPredicate(format: "kind = 1 AND SUBQUERY(eventReferences, $reference, $reference.marker = 'root' OR $reference.marker = 'reply' OR $reference.marker = nil).@count = 0 AND ANY author.followers.source.hexadecimalPublicKey = %@", currentUserKey)
            // swiftlint:enable line_length
        }

        if let follows = CurrentUser.shared.follows {
            let authors = follows.keys
            
            if !authors.isEmpty {
                let textFilter = Filter(authorKeys: authors, kinds: [.text], limit: 100)
                let textSub = relayService.requestEventsFromAll(filter: textFilter)
                subscriptionIds.append(textSub)
            }
            if let currentUser = CurrentUser.shared.author {
                let currentUserAuthorKeys = [currentUser.hexadecimalPublicKey!]
                let userLikesFilter = Filter(
                    authorKeys: currentUserAuthorKeys,
                    kinds: [.like],
                    limit: 100
                )
                let userLikesSub = relayService.requestEventsFromAll(filter: userLikesFilter)
                subscriptionIds.append(userLikesSub)
            }
        }
    }
    
    var body: some View {
        ScrollView(.vertical) {
            LazyVStack {
                ForEach(events.unmuted) { event in
                    VStack {
                        NoteButton(note: event, hideOutOfNetwork: false)
                            .padding(.horizontal)
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
        .nosNavigationBar(title: .homeFeed)
        .refreshable {
            refreshHomeFeed()
        }
        .onAppear {
            analytics.showedHome()
        }
        .task {
            refreshHomeFeed()
        }
        .onDisappear {
            relayService.sendCloseToAll(subscriptions: subscriptionIds)
            subscriptionIds.removeAll()
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
        let currentUser = CurrentUser()
        currentUser.context = previewContext
        currentUser.relayService = relayService
        currentUser.keyPair = KeyFixture.keyPair
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
