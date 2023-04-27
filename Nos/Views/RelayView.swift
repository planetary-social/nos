//
//  RelayView.swift
//  Nos
//
//  Created by Matthew Lorentz on 1/31/23.
//

import SwiftUI
import CoreData
import Dependencies
import SwiftUINavigation

struct RelayView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var relayService: RelayService
    @ObservedObject var author: Author
    
    @State var newRelayAddress: String = ""
    
    @EnvironmentObject private var router: Router
    
    @State private var alert: AlertState<Never>?
    
    @Dependency(\.analytics) private var analytics
    
    @FetchRequest var relays: FetchedResults<Relay>
    
    init(author: Author) {
        self.author = author
        _relays = FetchRequest(fetchRequest: Relay.relays(for: author))
    }
    
    var body: some View {
        List {
            Section {
                ForEach(relays) { relay in
                    Text(relay.address ?? Localized.error.string)
                        .foregroundColor(.textColor)
                }
                .onDelete { indexes in
                    Task {
                        for index in indexes {
                            let relay = relays[index]
                            await relayService.closeConnection(to: relay)
                            analytics.removed(relay)
                            author.remove(relay: relay)
                            viewContext.delete(relay)
                        }
                        
                        try! viewContext.save()
                        await publishChanges()
                    }
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
                            Task {
                                await CurrentUser.shared.subscribe()
                                await publishChanges()
                            }
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
            
            Section {
                TextField(Localized.relayAddressPlaceholder.string, text: $newRelayAddress)
                    .foregroundColor(.textColor)
                    .autocorrectionDisabled()
                    #if os(iOS)
                    .textInputAutocapitalization(.none)
                    .keyboardType(.URL)
                    #endif
                Button(Localized.save.string) {
                    addRelay()
                    Task {
                        await CurrentUser.shared.subscribe()
                        await publishChanges()
                    }
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
        .alert(unwrapping: $alert)
        .scrollContentBackground(.hidden)
        .background(Color.appBg)
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
            #endif
        }
        .nosNavigationBar(title: .relays)
        .onAppear {
            analytics.showedRelays()
        }
    }
    
    func publishChanges() async {
        let followKeys = CurrentUser.shared.socialGraph.followedKeys 
        await CurrentUser.shared.publishContactList(tags: followKeys.pTags)
    }

    private func addRelay() {
        withAnimation {
            guard !newRelayAddress.isEmpty else { return }
            
            do {
                let address = newRelayAddress.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                let relay = try Relay.findOrCreate(by: address, context: viewContext)
                CurrentUser.shared.author?.add(relay: relay)
                try viewContext.save()
                analytics.added(relay)
                newRelayAddress = ""
            } catch {
                var errorMessage: String
                if error as? RelayError == RelayError.invalidAddress {
                    errorMessage = Localized.invalidURLError.string
                } else {
                    errorMessage = Localized.saveRelayError.string
                }
                alert = AlertState(title: {
                    TextState(Localized.error.string)
                }, message: {
                    TextState(errorMessage)
                })
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
