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

    @FetchRequest(fetchRequest: Event.allPostsRequest(), animation: .default)
    private var events: FetchedResults<Event>
    
    @EnvironmentObject var router: Router
    
    class SyncTimer {
        let currentTimePublisher = Timer.TimerPublisher(interval: 1.0, runLoop: .main, mode: .default)
        let cancellable: AnyCancellable?

        init() {
            self.cancellable = currentTimePublisher.connect() as? AnyCancellable
        }

        deinit {
            self.cancellable?.cancel()
        }
    }

    let syncTimer = SyncTimer()
    
    @State private var authorsToSync: [Author] = []
    
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
        }

        .overlay(Group {
            if events.isEmpty {
                Localized.noEvents.view
                    .padding()
            }
        })
        .task {
            load()
        }
        .refreshable {
            load()
        }
        .onReceive(syncTimer.currentTimePublisher) { _ in
            if !authorsToSync.isEmpty {
                print("Syncing \(authorsToSync.count) authors")
                let filter = Filter(authors: authorsToSync, kinds: [.metaData], limit: authorsToSync.count)
                relayService.requestEventsFromAll(filter: filter)
                authorsToSync.removeAll()
            }
        }
    }
    
    private func load() {
        Profile.relayService = relayService
        
        if Profile.author == nil {
            let author = try! Author.findOrCreate(by: KeyChain.publicKey, context: viewContext)
            let filter = Filter(authors: [author], kinds: [.metaData], limit: 100)
            relayService.requestEventsFromAll(filter: filter)
        } else {
            if let follows = Profile.follows {
                let authors = follows.map { $0.event!.author! }
                let filter = Filter(authors: authors, kinds: [.text], limit: 100)
                relayService.requestEventsFromAll(filter: filter)
            } else {
                print("No follows found! Syncing contacts...")
                let filter = Filter(authors: [Profile.author!], kinds: [.contactList], limit: 100)
                relayService.requestEventsFromAll(filter: filter)
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
        return note
    }
    
    static var longNote: Event {
        let note = Event(context: previewContext)
        note.content = .loremIpsum(5)
        return note
    }
    
    static var previews: some View {
        NavigationView {
            HomeFeedView()
        }
        .environment(\.managedObjectContext, previewContext)
        .environmentObject(relayService)
        
        NavigationView {
            HomeFeedView()
        }
        .environment(\.managedObjectContext, emptyPreviewContext)
        .environmentObject(emptyRelayService)
    }
}
