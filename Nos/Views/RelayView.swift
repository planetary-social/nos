//
//  RelayView.swift
//  Nos
//
//  Created by Matthew Lorentz on 1/31/23.
//

import SwiftUI
import CoreData

struct RelayView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @State var newRelayAddress: String = ""
    
    @FetchRequest(fetchRequest: Relay.allRelaysRequest(), animation: .default)
    private var relays: FetchedResults<Relay>
    
    @EnvironmentObject var router: Router
    
    var body: some View {
        NavigationStack(path: $router.path) {
            List {
                Section(Localized.relays.string) {
                    ForEach(relays) { relay in
                        Text(relay.address ?? Localized.error.string)
                    }
                    .onDelete { indexes in
                        for index in indexes {
                            let relay = relays[index]
                            viewContext.delete(relay)
                        }
                    }
                    if relays.isEmpty {
                        Localized.noRelaysMessage.view
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
                    }
                }
                if relays.isEmpty {
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
    
    private func addRelay() {
        withAnimation {
            let relay = Relay(context: viewContext)
            relay.address = newRelayAddress.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

            do {
                try viewContext.save()
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
    
    static var previews: some View {
        NavigationStack {
            RelayView()
        }.environment(\.managedObjectContext, previewContext)
        
        NavigationStack {
            RelayView()
        }.environment(\.managedObjectContext, emptyContext)
    }
}
