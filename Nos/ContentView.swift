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
                                .lineLimit(5)
                            Spacer()
                            Text("Kind: \(event.kind)")
                                .bold()
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
                    Button("Relays") {
                        
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
    }

    private func addItem() {
        withAnimation {
            let newItem = Event(context: viewContext)
            newItem.createdAt = Date()
            newItem.content = "Hello, world"
            newItem.identifier = "984kljsdhf"
            newItem.kind = 1
            newItem.signature = "definitely valid"

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
    
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, previewContext)
    }
}
