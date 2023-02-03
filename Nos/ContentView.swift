//
//  ContentView.swift
//  Nos
//
//  Created by Matthew Lorentz on 1/31/23.
//

import SwiftUI
import CoreData

struct ContentView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @EnvironmentObject private var relayService: RelayService

    @FetchRequest(fetchRequest: Event.allPostsRequest(), animation: .default)
    private var events: FetchedResults<Event>

    var body: some View {
        NavigationView {
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
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink("Relays") {
                        RelayView()
                    }
                }
#endif
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            .navigationTitle("Posts")
        }
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
        withAnimation {
            let event = Event(context: viewContext)
            event.createdAt = Date()
            event.content = "Hello from Nos!"
            event.kind = 1
            
            let author = PubKey(entity: NSEntityDescription.entity(forEntityName: "PubKey", in: viewContext)!, insertInto: viewContext)
            author.hex = "32730e9dfcab797caf8380d096e548d9ef98f3af3000542f9271a91a9e3b0001"
            event.author = author
            

            do {
                try event.sign(withKey: "69222a82c30ea0ad472745b170a560f017cb3bcc38f927a8b27e3bab3d8f0f19")
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
    
    static var previewContext = PersistenceController.preview.container.viewContext
    static var relayService = PersistenceController.preview.container.viewContext
    
    
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, previewContext)
    }
}
