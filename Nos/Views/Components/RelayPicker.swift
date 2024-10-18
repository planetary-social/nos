import SwiftUI
import CoreData

struct RelayPicker: View {
    
    @Binding var selectedRelay: Relay?
    @Binding var isPresented: Bool
    
    var defaultSelection: String
    
    @FetchRequest var relays: FetchedResults<Relay>
    
    init(selectedRelay: Binding<Relay?>, defaultSelection: String, author: Author, isPresented: Binding<Bool>) {
        self._selectedRelay = selectedRelay
        self.defaultSelection = defaultSelection
        _relays = FetchRequest(fetchRequest: Relay.relays(for: author))
        _isPresented = isPresented
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            let pickerRows = VStack(spacing: 0) {
                // shadow effect at the top
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(.clear)
                    .shadow(radius: 15, y: 10)
                
                RelayPickerRow(string: defaultSelection, selection: $selectedRelay)
                ForEach(relays) { relay in
                    
                    BeveledSeparator()
                        .padding(.horizontal, 20)
                    
                    RelayPickerRow(relay: relay, selection: $selectedRelay)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .background(
                Rectangle()
                    .foregroundStyle(LinearGradient.cardBackground)
                    .cornerRadius(20, corners: [.bottomLeft, .bottomRight])
                    .shadow(radius: 15, y: 10)
            ) 
            .readabilityPadding()
            
            VStack(spacing: 0) {
                ViewThatFits(in: .vertical) {
                    VStack {
                        pickerRows
                        Color.clear
                            .contentShape(Rectangle())
                            .frame(minHeight: 0)
                            .onTapGesture { 
                                withAnimation {
                                    isPresented = false
                                }
                            }
                    }
                    ScrollView {
                        pickerRows
                    }
                }
            }
        }
        .transition(.move(edge: .top))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            return relay.host ?? String(localized: "error")
        } else {
            return defaultSelection ?? String(localized: "error")
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
                VStack(spacing: 6) {
                    HStack {
                        Text(title)
                            .foregroundColor(.primaryTxt)
                            .font(.clarity(.bold))
                            .lineLimit(1)
                            .shadow(radius: 4, y: 4)
                        Spacer()
                    }
                    
                    if let description = relay?.relayDescription {
                        HStack {
                            Text(description)
                                .font(.clarityRegular(.callout))
                                .multilineTextAlignment(.leading)
                                .foregroundColor(.secondaryTxt)
                                .lineLimit(2)
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
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

#Preview("Without ScrollView") {

    @State var selectedRelay: Relay?
    var previewData = PreviewData()
    
    func createTestData() {
        let user = previewData.alice
        let addresses = ["wss://nostr.com", "wss://nos.social", "wss://alongdomainnametoseewhathappens.com"]
        addresses.forEach { address in
            let relay = try? Relay.findOrCreate(by: address, context: previewData.previewContext)
            relay?.relayDescription = "A Nostr relay that aims to cultivate a healthy community."
            relay?.addToAuthors(user)
        }
    }
    
    return RelayPicker(
        selectedRelay: $selectedRelay,
        defaultSelection: String(localized: "allMyRelays"),
        author: previewData.alice,
        isPresented: .constant(true)
    )
    .onAppear { createTestData() }
    .inject(previewData: previewData)
    .background(Color.appBg)
}

#Preview("With ScrollView") {

    @State var selectedRelay: Relay?
    var previewData = PreviewData()
    
    func createTestData() {
        let user = previewData.alice
        let addresses = Relay.allKnown
        addresses.forEach { address in
            let relay = try? Relay.findOrCreate(by: address, context: previewData.previewContext)
            relay?.relayDescription = "A Nostr relay that aims to cultivate a healthy community."
            relay?.addToAuthors(user)
        }
    }
    
    return RelayPicker(
        selectedRelay: $selectedRelay,
        defaultSelection: String(localized: "allMyRelays"),
        author: previewData.alice,
        isPresented: .constant(true)
    )
    .onAppear { createTestData() }
    .inject(previewData: previewData)
    .background(Color.appBg)
}
