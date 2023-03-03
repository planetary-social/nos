//
//  HomeFeedView.swift
//  Nos
//
//  Created by Matthew Lorentz on 1/31/23.
//

import SwiftUI
import CoreData
import Combine

struct HomeFeedView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @EnvironmentObject private var relayService: RelayService

    @EnvironmentObject var router: Router
    
    private var eventRequest: FetchRequest<Event> = FetchRequest(fetchRequest: Event.fetchRequest())

    private var events: FetchedResults<Event> { eventRequest.wrappedValue }
    
    // Probably the logged in user should be in the @Environment eventually
    private var user: Author?
    
    @State private var subscriptionIds: [String] = []
    
    init(user: Author?) {
        self.user = user
        if let user {
            eventRequest = FetchRequest(fetchRequest: Event.homeFeed(for: user))
        }
    }

    func refreshHomeFeed() {
        // Close out stale requests
        if !subscriptionIds.isEmpty {
            relayService.sendCloseToAll(subscriptions: subscriptionIds)
            subscriptionIds.removeAll()
        }

        if let follows = CurrentUser.author.follows as? Set<Follow> {
            let authors = follows.compactMap({ $0.destination?.hexadecimalPublicKey! })
            
            if !authors.isEmpty {
                let textFilter = Filter(authorKeys: authors, kinds: [.text], limit: 100)
                let textSub = relayService.requestEventsFromAll(filter: textFilter)
                subscriptionIds.append(textSub)
                
                let metaFilter = Filter(authorKeys: authors, kinds: [.metaData, .contactList], limit: 100)
                let metaSub = relayService.requestEventsFromAll(filter: metaFilter)
                subscriptionIds.append(metaSub)
            }
        }
    }
    
    var body: some View {
        NavigationStack(path: $router.path) {
            ScrollView(.vertical) {
                LazyVStack {
                    ForEach(events) { event in
                        VStack {
                            NoteButton(note: event)
                                .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.top, 1)
            .navigationDestination(for: Event.self) { note in
                ThreadView(note: note)
            }
            .navigationDestination(for: Author.self) { author in
                ProfileView(author: author)
            }
            .navigationDestination(for: AppView.Destination.self) { destination in
                if destination == AppView.Destination.settings {
                    SettingsView()
                }
            }
            .overlay(Group {
                if events.isEmpty {
                    Localized.noEvents.view
                        .padding()
                }
            })
        }
        .task {
            CurrentUser.context = viewContext
            CurrentUser.relayService = relayService
            refreshHomeFeed()
        }
        .refreshable {
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
        NavigationView {
            HomeFeedView(user: user)
        }
        .environment(\.managedObjectContext, previewContext)
        .environmentObject(relayService)
        .environmentObject(router)
        
        NavigationView {
            HomeFeedView(user: user)
        }
        .environment(\.managedObjectContext, emptyPreviewContext)
        .environmentObject(emptyRelayService)
        .environmentObject(router)
    }
}
