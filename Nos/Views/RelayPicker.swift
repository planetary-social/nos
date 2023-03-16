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
    
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest var relays: FetchedResults<Relay>
    
    init(selectedRelay: Binding<Relay?>, author: Author) {
        self._selectedRelay = selectedRelay
        _relays = FetchRequest(fetchRequest: Relay.relays(for: author))
    }
    
    var body: some View {
        Form {
            RelayPickerRow(relay: nil, selection: $selectedRelay)
            ForEach(relays) { relay in
                RelayPickerRow(relay: relay, selection: $selectedRelay)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBg)
    }
}

struct RelayPickerRow: View {
    
    var relay: Relay?
    @Binding var selection: Relay?
    
    var title: String {
        if let relay {
            return relay.host ?? Localized.error.string
        } else {
            return Localized.extendedNetwork.string
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
                    .foregroundColor(.textColor)
                    .lineLimit(1)
                Spacer()
                if isSelected {
                    Image.checkmark
                        .offset(y: 4)
                }
            }
        }
        .listRowBackground(LinearGradient(
            colors: [Color.cardBgTop, Color.cardBgBottom],
            startPoint: .top,
            endPoint: .bottom
        ))
    }
}

struct RelayPicker_Previews: PreviewProvider {

    static var persistenceController = PersistenceController.preview
    static var previewContext = persistenceController.container.viewContext
    static var relayService = RelayService(persistenceController: persistenceController)
    
    static var user: Author {
        let author = Author(context: previewContext)
        author.hexadecimalPublicKey = KeyFixture.alice.publicKeyHex
        createTestData(in: previewContext, user: author)
        return author
    }
    
    static func createTestData(in context: NSManagedObjectContext, user: Author) {
        let addresses = ["wss://nostr.band", "wss://nos.social", "wss://a.long.domain.name.to.see.what.happens"]
        addresses.forEach {
            try! Relay(context: previewContext, address: $0, author: user)
        }
        
        try! previewContext.save()
    }
    
    @State static var selectedRelay: Relay?
    
    static var previews: some View {
        RelayPicker(selectedRelay: $selectedRelay, author: user)
            .environment(\.managedObjectContext, previewContext)
    }
}
