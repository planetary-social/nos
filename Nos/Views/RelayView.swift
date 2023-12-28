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

struct RelaysDestination: Hashable {
    var author: Author
    var relays: [Relay]
}

struct RelayView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var relayService: RelayService
    @Environment(CurrentUser.self) private var currentUser
    @ObservedObject var author: Author
    
    @State var newRelayAddress: String = ""
    
    @EnvironmentObject private var router: Router
    
    @State private var alert: AlertState<Never>?
    
    @Dependency(\.analytics) private var analytics
    @Dependency(\.crashReporting) private var crashReporting
    
    @FetchRequest var relays: FetchedResults<Relay>

    var editable: Bool
    
    init(author: Author, editable: Bool = true) {
        self.author = author
        self.editable = editable
        _relays = FetchRequest(fetchRequest: Relay.relays(for: author))
    }
    
    var body: some View {
        List {
            Section {
                ForEach(relays) { relay in
                    VStack(alignment: .leading) {
                        if relay.hasMetadata {
                            NavigationLink {
                                RelayDetailView(relay: relay)
                            } label: {
                                Text(relay.address ?? String(localized: .localizable.error))
                                    .foregroundColor(.primaryTxt)
                            }
                        } else {
                            Text(relay.address ?? String(localized: .localizable.error))
                                .foregroundColor(.primaryTxt)
                                .textSelection(.enabled)
                        }
                    }
                }
                .onDelete { indexes in
                    Task {
                        for index in indexes {
                            let relay = relays[index]
                            await relayService.closeConnection(to: relay.address)
                            analytics.removed(relay)
                            author.remove(relay: relay)
                            viewContext.delete(relay)
                        }

                        do {
                            try viewContext.save()
                            await publishChanges()
                        } catch {
                            crashReporting.report(error)
                        }
                    }
                }
                
                if author.relays.count == 0, editable {
                    Text(.localizable.noRelaysMessage)
                }
            } header: {
                if editable {
                    Text(.localizable.relays)
                        .foregroundColor(.primaryTxt)
                        .fontWeight(.heavy)
                }
            }
            .deleteDisabled(!editable)
            .listRowBackground(LinearGradient(
                colors: [Color.cardBgTop, Color.cardBgBottom],
                startPoint: .top,
                endPoint: .bottom
            ))
            
            let authorRelayUrls = author.relays.compactMap { $0.address }
            let recommendedRelays = Relay.recommended.filter { !authorRelayUrls.contains($0) }
            
            if editable, !recommendedRelays.isEmpty {
                Section {
                    ForEach(recommendedRelays, id: \.self) { address in
                        Button {
                            newRelayAddress = address
                            addRelay()
                            Task {
                                await currentUser.subscribe()
                                await publishChanges()
                            }
                        } label: {
                            Label(address, systemImage: "plus.circle")
                        }
                    }
                } header: {
                    Text(.localizable.recommendedRelays)
                        .foregroundColor(.primaryTxt)
                        .fontWeight(.heavy)
                }
                .listRowBackground(LinearGradient(
                    colors: [Color.cardBgTop, Color.cardBgBottom],
                    startPoint: .top,
                    endPoint: .bottom
                ))
            }
            
            if editable {
                Section {
                    TextField(String(localized: .localizable.relayAddressPlaceholder), text: $newRelayAddress)
                        .foregroundColor(.primaryTxt)
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .textInputAutocapitalization(.none)
                        .keyboardType(.URL)
                        #endif
                    Button(String(localized: .localizable.save)) {
                        addRelay()
                        Task {
                            await currentUser.subscribe()
                            await publishChanges()
                        }
                    }
                } header: {
                    Text(.localizable.addRelay)
                        .foregroundColor(.primaryTxt)
                        .fontWeight(.heavy)
                        .bold()
                }
                .listRowBackground(LinearGradient(
                    colors: [Color.cardBgTop, Color.cardBgBottom],
                    startPoint: .top,
                    endPoint: .bottom
                ))
            }
        }
        .alert(unwrapping: $alert)
        .scrollContentBackground(.hidden)
        .background(Color.appBg)
        .toolbar {
            if editable {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                #endif
            }
        }
        .nosNavigationBar(title: .localizable.relays)
        .onAppear {
            analytics.showedRelays()
        }
    }
    
    func publishChanges() async {
        let followKeys = await Array(currentUser.socialGraph.followedKeys)
        await currentUser.publishContactList(tags: followKeys.pTags)
    }

    private func addRelay() {
        withAnimation {
            guard !newRelayAddress.isEmpty else { return }
            
            do {
                let address = newRelayAddress.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                let relay = try Relay.findOrCreate(by: address, context: viewContext)
                currentUser.author?.add(relay: relay)
                try viewContext.save()
                analytics.added(relay)
                newRelayAddress = ""
            } catch {
                var errorMessage: LocalizedStringResource
                if error as? RelayError == RelayError.invalidAddress {
                    errorMessage = .localizable.invalidURLError
                } else {
                    errorMessage = .localizable.saveRelayError
                }
                alert = AlertState(title: {
                    TextState(String(localized: .localizable.error))
                }, message: {
                    TextState(String(localized: errorMessage))
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
