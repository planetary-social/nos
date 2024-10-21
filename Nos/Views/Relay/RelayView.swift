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
    
    @State private var alert: AlertState<Never>?
    
    @Dependency(\.analytics) private var analytics
    @Dependency(\.crashReporting) private var crashReporting
    
    @FetchRequest var relays: FetchedResults<Relay>

    private var sortedRelays: [Relay] {
        relays.sorted { (lhs, _) in
            lhs.address == Relay.nosAddress.absoluteString
        }
    }

    var editable: Bool
    
    init(author: Author, editable: Bool = true) {
        self.author = author
        self.editable = editable
        _relays = FetchRequest(fetchRequest: Relay.relays(for: author))
    }
    
    var body: some View {
        List {
            Section {
                Text("relaysImportantMessage")
                    .font(.clarity(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())

            Section {
                ForEach(sortedRelays) { relay in
                    VStack(alignment: .leading) {
                        if relay.hasMetadata {
                            NavigationLink {
                                RelayDetailView(relay: relay)
                            } label: {
                                Text(relay.host ?? String(localized: "error"))
                                    .foregroundColor(.primaryTxt)
                            }
                        } else {
                            Text(relay.host ?? String(localized: "error"))
                                .foregroundColor(.primaryTxt)
                                .textSelection(.enabled)
                        }
                    }
                }
                .onDelete { indexes in
                    Task {
                        for index in indexes {
                            let relay = sortedRelays[index]
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
                    Text("noRelaysMessage")
                }
            } header: {
                if editable {
                    Text("relays")
                        .foregroundColor(.primaryTxt)
                        .font(.clarity(.semibold, textStyle: .headline))
                        .padding(.bottom, 15)
                        .textCase(nil)
                        .listRowInsets(EdgeInsets())
                }
            }
            .deleteDisabled(!editable)
            .listRowGradientBackground()
            
            let authorRelayUrls = author.relays.compactMap { $0.address }
            let recommendedRelays = Relay.recommended
                .filter { !authorRelayUrls.contains($0) }
                .map { $0.replacingOccurrences(of: "wss://", with: "") }
                .sorted { (lhs, _) in lhs == Relay.nosAddress.absoluteString }

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
                    Text("recommendedRelays")
                        .foregroundColor(.primaryTxt)
                        .font(.clarity(.semibold, textStyle: .headline))
                        .padding(.vertical, 15)
                        .textCase(nil)
                        .listRowInsets(EdgeInsets())
                }
                .listRowGradientBackground()
            }
            
            if editable {
                Section {
                    HStack {
                        TextField("relayAddressPlaceholder", text: $newRelayAddress)
                            .foregroundColor(.primaryTxt)
                            .autocorrectionDisabled()
                            #if os(iOS)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.URL)
                            #endif
                        SecondaryActionButton("save") {
                            addRelay()
                            Task {
                                await currentUser.subscribe()
                                await publishChanges()
                            }
                        }
                    }
                } header: {
                    Text("addRelay")
                        .foregroundColor(.primaryTxt)
                        .font(.clarity(.semibold, textStyle: .headline))
                        .padding(.vertical, 15)
                        .textCase(nil)
                        .listRowInsets(EdgeInsets())
                }
                .listRowGradientBackground()
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
        .nosNavigationBar("relays")
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
                var address = newRelayAddress.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                if !address.starts(with: "wss://") {
                    address = "wss://" + address
                }
                let relay = try Relay.findOrCreate(by: address, context: viewContext)
                currentUser.author?.add(relay: relay)
                try viewContext.save()
                analytics.added(relay)
                newRelayAddress = ""
            } catch {
                let errorMessage: String
                if error as? RelayError == RelayError.invalidAddress {
                    errorMessage = String(localized: "invalidURLError")
                } else {
                    errorMessage = String(localized: "saveRelayError")
                }
                alert = AlertState(title: {
                    TextState(String(localized: "error"))
                }, message: {
                    TextState(errorMessage)
                })
            }
        }
    }
}

struct RelayView_Previews: PreviewProvider {
    
    static var previewData = PreviewData()
    static var previewContext = PersistenceController.preview.viewContext
    
    static var emptyContext = PersistenceController.empty.viewContext

    static var user: Author {
        let author = Author(context: previewContext)
        author.hexadecimalPublicKey = "d0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e"
        return author
    }
    
    static var previews: some View {
        NavigationStack {
            RelayView(author: user)
        }
        .inject(previewData: previewData)

        NavigationStack {
            RelayView(author: user)
        }
        .environment(\.managedObjectContext, emptyContext)
        .environment(previewData.currentUser)
    }
}
