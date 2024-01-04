//
//  RelayPicker.swift
//  Nos
//
//  Created by Matthew Lorentz on 3/16/23.
//

import SwiftUI
import CoreData

struct RelayPicker: View {
    
    @Binding var selectedRelay: Relay?
    @Binding var isPresented: Bool
    
    var defaultSelection: String
    
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest var relays: FetchedResults<Relay>
    
    init(selectedRelay: Binding<Relay?>, defaultSelection: String, author: Author, isPresented: Binding<Bool>) {
        self._selectedRelay = selectedRelay
        self.defaultSelection = defaultSelection
        _relays = FetchRequest(fetchRequest: Relay.relays(for: author))
        _isPresented = isPresented
    }
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 0) {
                    // TODO: scrolling
                    RelayPickerRow(string: defaultSelection, selection: $selectedRelay)
                    ForEach(relays) { relay in

                        BeveledSeparator()
                            .padding(.horizontal, 20)
                        
                        RelayPickerRow(relay: relay, selection: $selectedRelay)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .cornerRadius(15, corners: [.bottomLeft, .bottomRight])
            }
            Spacer()
        }
        .background(LinearGradient.cardBackground) 
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.move(edge: .top))
        .zIndex(99) // Fixes dismissal animation
    }
}

struct RelayPickerRow: View {
    
    var relay: Relay?
    var defaultSelection: String?
    @Binding var selection: Relay?
    
    internal init(relay: Relay? = nil, selection: Binding<Relay?>) {
        self.relay = relay
        self._selection = selection
    }
    
    internal init(string: String, selection: Binding<Relay?>) {
        self.defaultSelection = string
        self._selection = selection
    }
    
    var title: String {
        if let relay {
            return relay.host ?? String(localized: .localizable.error)
        } else {
            return defaultSelection ?? String(localized: .localizable.error)
        }
    }
    
    var isSelected: Bool {
        if let relay {
            return relay.objectID == selection?.objectID
        } else {
            return selection == nil
        }
    }
    
    var body: some View {
        Button {
            selection = relay
        } label: {
            HStack {
                Text(title)
                    .foregroundColor(.primaryTxt)
                    .bold()
                    .lineLimit(1)
                    .padding(.horizontal, 19)
                    .padding(.vertical, 19)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .bold()
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(LinearGradient.diagonalAccent)
                        .padding(.trailing, 19)
                }
            }
            .readabilityPadding()
        }
    }
}

struct RelayPicker_Previews: PreviewProvider {

    static var previewData = PreviewData()
    static var persistenceController = PersistenceController.preview
    static var previewContext = persistenceController.container.viewContext
    static var relayService = previewData.relayService
    
    static var user: Author {
        let author = Author(context: previewContext)
        author.hexadecimalPublicKey = KeyFixture.alice.publicKeyHex
        createTestData(in: previewContext, user: author)
        return author
    }
    
    static func createTestData(in context: NSManagedObjectContext, user: Author) {
        let addresses = ["wss://nostr.com", "wss://nos.social", "wss://alongdomainnametoseewhathappens.com"]
        addresses.forEach {
            do {
                _ = try Relay(context: previewContext, address: $0, author: user)
            } catch {
                print(error)
            }
        }

        try? previewContext.save()
    }
    
    @State static var selectedRelay: Relay?
    
    static var previews: some View {
        RelayPicker(
            selectedRelay: $selectedRelay,
            defaultSelection: String(localized: .localizable.allMyRelays),
            author: user,
            isPresented: .constant(true)
        )
        .environment(\.managedObjectContext, previewContext)
        .background(Color.appBg)
    }
}
