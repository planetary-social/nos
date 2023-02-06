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
    
    @State var isCreatingNewPost = false

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
        }
        .sheet(isPresented: $isCreatingNewPost, content: {
            NewPostView(isPresented: $isCreatingNewPost)
        })
        .overlay(Group {
            if events.isEmpty {
                Text("No Events Yet! Add a relay to get started")
            }
        })
        .toolbar {
            ToolbarItem {
                Button(action: { isCreatingNewPost.toggle() }) {
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
