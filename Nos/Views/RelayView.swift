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
    
    @EnvironmentObject private var router: Router
    
    @Dependency(\.analytics) private var analytics
    
    var body: some View {
        List {
            if let relays = author.relays?.allObjects as? [Relay] {
                Section {
                    ForEach(relays) { relay in
                        Text(relay.address ?? Localized.error.string)
                            .foregroundColor(.textColor)
                    }
                    .onDelete { indexes in
                        for index in indexes {
                            let relay = relays[index]
                            relayService.closeConnection(to: relay)
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
                } header: {
                    Localized.relays.view
                        .foregroundColor(.textColor)
                        .fontWeight(.heavy)
                }
                .listRowBackground(LinearGradient(
                    colors: [Color.cardBgTop, Color.cardBgBottom],
                    startPoint: .top,
                    endPoint: .bottom
                ))
                
                let authorRelayUrls = (author.relays as? Set<Relay>)?.compactMap { $0.address } ?? []
                let recommendedRelays = Relay.recommended.filter { !authorRelayUrls.contains($0) }
                
                if !recommendedRelays.isEmpty {
                    Section {
                        ForEach(recommendedRelays, id: \.self) { address in
                            Button {
                                newRelayAddress = address
                                addRelay()
                                CurrentUser.shared.subscribe()
                                publishChanges()
                            } label: {
                                Label(address, systemImage: "plus.circle")
                            }
                        }
                    } header: {
                        Localized.recommendedRelays.view
                            .foregroundColor(.textColor)
                            .fontWeight(.heavy)
                    }
                    .listRowBackground(LinearGradient(
                        colors: [Color.cardBgTop, Color.cardBgBottom],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                }
            }
            
            Section {
                TextField("wss://yourrelay.com", text: $newRelayAddress)
                    .foregroundColor(.textColor)
                    .autocorrectionDisabled()
                    #if os(iOS)
                    .textInputAutocapitalization(.none)
                    .keyboardType(.URL)
                    #endif
                Button(Localized.save.string) {
                    addRelay()
                    CurrentUser.shared.subscribe()
                    publishChanges()
                }
            } header: {
                Localized.addRelay.view
                    .foregroundColor(.textColor)
                    .fontWeight(.heavy)
                    .bold()
            }
            .listRowBackground(LinearGradient(
                colors: [Color.cardBgTop, Color.cardBgBottom],
                startPoint: .top,
                endPoint: .bottom
            ))
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBg)
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
            #endif
        }
        .navigationBarTitle(Localized.relays.string, displayMode: .inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.cardBgBottom, for: .navigationBar)
        .onAppear {
            analytics.showedRelays()
        }
    }
    
    func publishChanges() {
        let followKeys = CurrentUser.shared.follows?.keys ?? []
        CurrentUser.shared.publishContactList(tags: followKeys.tags)
    }

    private func addRelay() {
        withAnimation {
            guard !newRelayAddress.isEmpty else { return }
            
            let address = newRelayAddress.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            let relay = Relay.findOrCreate(by: address, context: viewContext)
            CurrentUser.shared.author?.add(relay: relay)
            newRelayAddress = ""

            do {
                try viewContext.save()
                analytics.added(relay)
                newRelayAddress = ""
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
