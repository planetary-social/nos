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
        ZStack {
            VStack {
                Color.clear
            }.onTapGesture {
                // TODO: this doesn't work when color is clear
                withAnimation {
                    isPresented = false
                }
            }
            VStack {
                VStack(spacing: 0) {
                    RelayPickerRow(string: defaultSelection, selection: $selectedRelay)
                    ForEach(relays) { relay in
                        Color.separatorDefault
                            .frame(height: 1)
                            .shadow(color: Color(hex: "#3A2859"), radius: 0, y: 1)
                        RelayPickerRow(relay: relay, selection: $selectedRelay)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .cornerRadius(15, corners: [.bottomLeft, .bottomRight])
                Spacer()
            }
            VStack {
                Color.white
                    .frame(height: 100)
                    .offset(y: -100)
                    .shadow(radius: 10, y: 0)
                Spacer()
            }
            .clipped()
        }
        .transition(.move(edge: .top))
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
            return relay.host ?? Localized.error.string
        } else {
            return defaultSelection ?? Localized.error.string
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
                    .padding(.horizontal, 14)
                    .padding(.vertical, 19)
                Spacer()
                if isSelected {
                    Image.checkmark
                        .offset(y: 4)
                }
            }
            .background(Color.cardBgBottom)
        }
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
        let addresses = ["wss://nostr.com", "wss://nos.social", "wss://alongdomainnametoseewhathappens.com"]
        addresses.forEach {
            try! Relay(context: previewContext, address: $0, author: user)
        }
        
        try! previewContext.save()
    }
    
    @State static var selectedRelay: Relay?
    
    static var previews: some View {
        RelayPicker(selectedRelay: $selectedRelay, defaultSelection: Localized.extendedNetwork.string, author: user, isPresented: .constant(true))
            .environment(\.managedObjectContext, previewContext)
    }
}
