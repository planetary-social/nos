//
//  RelayView.swift
//  Nos
//
//  Created by Matthew Lorentz on 1/31/23.
//

import SwiftUI
import CoreData
import Dependencies

struct RelayView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var relayService: RelayService
    @ObservedObject var author: Author
    
    @State var newRelayAddress: String = ""
    
    @EnvironmentObject var router: Router
    
    @Dependency(\.analytics) private var analytics
    
    var body: some View {
        NavigationStack(path: $router.relayPath) {
            List {
                if let relays = author.relays?.allObjects as? [Relay] {
                    Section(Localized.relays.string) {
                        ForEach(relays) { relay in
                            Text(relay.address ?? Localized.error.string)
                        }
                        .onDelete { indexes in
                            for index in indexes {
                                let relay = relays[index]
                                
                                guard let address = relay.address else { continue }
                                
                                if let socket = relayService.socket(for: address) {
                                    for subId in relayService.activeSubscriptions {
                                        relayService.sendClose(from: socket, subscription: subId)
                                    }
                                    
                                    relayService.close(socket: socket)
                                }
                                
                                analytics.removed(relay)
                                author.remove(relay: relay)
                                viewContext.delete(relay)
                            }

                            try! viewContext.save()
                            
                            publishChanges()
                        }

                        if author.relays?.count == 0 {
                            Localized.noRelaysMessage.view
                        }
                    }
                }
                Section(Localized.addRelay.string) {
                    TextField("wss://yourrelay.com", text: $newRelayAddress)
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .textInputAutocapitalization(.none)
                        .keyboardType(.URL)
                        #endif
                    Button(Localized.save.string) {
                        addRelay()
                        CurrentUser.subscribe()
                        publishChanges()
                    }
                }
                if author.relays?.count == 0 {
                    Localized.noRelaysMessage.view
                }
            }
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                #endif
            }
            .navigationTitle(Localized.relays.string)
            .navigationDestination(for: Author.self) { author in
                ProfileView(author: author)
            }
        }
        .navigationTitle(Localized.relays.string)
    }
    
    func publishChanges() {
        let followKeys = CurrentUser.follows?.keys ?? []
        CurrentUser.publishContactList(tags: followKeys.tags, context: viewContext)
    }
    
    private func addRelay() {
        withAnimation {
            guard !newRelayAddress.isEmpty else { return }
            
            let relay = Relay(context: viewContext)
            relay.address = newRelayAddress.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            relay.createdAt = Date.now
            newRelayAddress = ""

            CurrentUser.author?.add(relay: relay)
            
            do {
                try viewContext.save()
                analytics.added(relay)
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not
                // use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct RelayView_Previews: PreviewProvider {
    
    static var previewContext = PersistenceController.preview.container.viewContext
    
    static var emptyContext = PersistenceController.empty.container.viewContext

    static var user: Author {
        let author = Author(context: previewContext)
        author.hexadecimalPublicKey = "d0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e"
        return author
    }
    
    static var previews: some View {
        NavigationStack {
            RelayView(author: user)
        }.environment(\.managedObjectContext, previewContext)
        
        NavigationStack {
            RelayView(author: user)
        }.environment(\.managedObjectContext, emptyContext)
    }
}
