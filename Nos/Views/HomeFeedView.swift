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
    
    let syncTimer = SyncTimer()
    
    @State private var authorsToSync: [Author] = []
    
    private var eventRequest: FetchRequest<Event> = FetchRequest(fetchRequest: Event.emptyRequest())
    private var events: FetchedResults<Event> { eventRequest.wrappedValue }
    
    private var user: Author?
    
    init(user: Author?) {
        self.user = user
        if let user {
            eventRequest = FetchRequest(fetchRequest: Event.homeFeed(for: user))
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
                        .onAppear {
                            // Error scenario: we have an event in core data without an author
                            guard let author = event.author else {
                                print("Event author is nil")
                                return
                            }
                            
                            if !author.isPopulated {
                                print("Need to sync author: \(author.hexadecimalPublicKey ?? "")")
                                authorsToSync.append(author)
                            }
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
            
            // TODO: Replace this with something more reliable
            let seconds = 2.0
            DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                CurrentUser.refreshHomeFeed()
            }
        }
        .refreshable {
            #if DEBUG
            print("Events: \(events.count)")
            #endif
            CurrentUser.refreshHomeFeed()
        }
        .onReceive(syncTimer.currentTimePublisher) { _ in
            if !authorsToSync.isEmpty {
                print("Syncing \(authorsToSync.count) authors")
                let keys = authorsToSync.map({ $0.hexadecimalPublicKey! })
                let filter = Filter(authorKeys: keys, kinds: [.metaData, .contactList], limit: 2 * authorsToSync.count)
                relayService.requestEventsFromAll(filter: filter)
                authorsToSync.removeAll()
            }
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
    
    static var shortNote: Event {
        let note = Event(context: previewContext)
        note.content = "Hello, world!"
        note.author = user
        return note
    }
    
    static var longNote: Event {
        let note = Event(context: previewContext)
        note.content = .loremIpsum(5)
        note.author = user
        return note
    }
    
    static var user: Author {
        let author = Author(context: previewContext)
        author.hexadecimalPublicKey = KeyFixture.pubKeyHex
        return author
    }
    
    static var previews: some View {
        NavigationView {
            HomeFeedView(user: user)
        }
        .environment(\.managedObjectContext, previewContext)
        .environmentObject(relayService)
        
        NavigationView {
            HomeFeedView(user: user)
        }
        .environment(\.managedObjectContext, emptyPreviewContext)
        .environmentObject(emptyRelayService)
    }
}
