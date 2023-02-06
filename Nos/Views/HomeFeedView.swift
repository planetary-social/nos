//
//  HomeFeedView.swift
//  Nos
//
//  Created by Matthew Lorentz on 1/31/23.
//

import SwiftUI
import CoreData

struct HomeFeedView: View {
    
    @AppStorage("keyPair") private var keyPair: KeyPair?
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @EnvironmentObject private var relayService: RelayService

    @FetchRequest(fetchRequest: Event.allPostsRequest(), animation: .default)
    private var events: FetchedResults<Event>

    var body: some View {
        List {
            ForEach(events) { event in
                VStack {
                    HStack {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.body)
                        
                        Text(event.author?.hex ?? "unknown")
                            .lineLimit(1)
                        Spacer()
                    }
                    
                    Text(event.content!)
                        .padding(.vertical, 1)
                }
            }
            .onDelete(perform: deleteItems)
        }
        .overlay(Group {
            if events.isEmpty {
                Text("No Events Yet! Add a relay to get started")
            }
        })
        .toolbar {
            ToolbarItem {
                Button(action: addItem) {
                    Label("Add Item", systemImage: "plus")
                }
            }
        }
        .navigationTitle("Home Feed")
        .task {
            load()
        }
        .refreshable {
            load()
        }
    }
    
    private func load() {
        relayService.requestEventsFromAll()
    }

    private func addItem() {
        guard let keyPair else {
            return
        }
        
        withAnimation {
            let event = Event(context: viewContext)
            event.createdAt = Date()
            event.content = "Hello from Nos!"
            event.kind = 1
            
            let author = PubKey(entity: NSEntityDescription.entity(forEntityName: "PubKey", in: viewContext)!, insertInto: viewContext)
            author.hex = "32730e9dfcab797caf8380d096e548d9ef98f3af3000542f9271a91a9e3b0001"
            event.author = author
            

            do {
                try event.sign(withKey: keyPair)
                try relayService.publish(event)
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { events[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
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
