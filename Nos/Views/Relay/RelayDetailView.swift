import SwiftUI

struct RelayDetailView: View {

    var relay: Relay

    func row(title: LocalizedStringResource, value: String) -> some View {
        HStack(alignment: .top) {
            Text("\(String(localized: title)): ")
                .font(.clarity(.regular))
            Text(value)
                .font(.clarity(.regular))
                .textSelection(.enabled)
        }
    }
    var body: some View {
        List {
            Section {
                Text(relay.address ?? String(localized: .localizable.error))
                    .font(.clarity(.regular))
                    .textSelection(.enabled)
            } header: {
                Text(.localizable.address)
                    .foregroundColor(.primaryTxt)
                    .font(.clarity(.bold))
            }
            .listRowBackground(LinearGradient(
                colors: [Color.cardBgTop, Color.cardBgBottom],
                startPoint: .top,
                endPoint: .bottom
            ))
            Section {
                if let name = relay.name {
                    row(title: .localizable.name, value: name)
                }
                if let description = relay.relayDescription {
                    row(title: .localizable.description, value: description)
                }
                if let supportedNIPs = relay.supportedNIPs {
                    row(
                        title: .localizable.supportedNIPs,
                        value: supportedNIPs.map { String($0) }.joined(separator: ", ")
                    )
                }
                if let pubkey = relay.pubkey {
                    row(title: .localizable.pubkey, value: pubkey)
                }
                if let contact = relay.contact {
                    row(title: .localizable.contact, value: contact)
                }
                if let software = relay.software {
                    row(title: .localizable.software, value: software)
                }
                if let version = relay.version {
                    row(title: .localizable.version, value: version)
                }
            } header: {
                Text(.localizable.metadata)
                    .foregroundColor(.primaryTxt)
                    .font(.clarity(.bold))
            } footer: {
                #if DEBUG
                if let date = relay.metadataFetchedAt {
                    Text("\(String(localized: .localizable.fetchedAt)): \(date.distanceString())")
                        .font(.clarity(.regular))
                }
                #endif
            }
            .listRowBackground(LinearGradient(
                colors: [Color.cardBgTop, Color.cardBgBottom],
                startPoint: .top,
                endPoint: .bottom
            ))
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBg)
        .nosNavigationBar(title: .localizable.relay)
    }
}

struct RelayDetailView_Previews: PreviewProvider {
    static var previewContext = PersistenceController.preview.container.viewContext
    static var relay: Relay {
        do {
            return try Relay.findOrCreate(by: "wss://example.com", context: previewContext) 
        } catch {
            return Relay(context: previewContext)
        }
    }
    static var previews: some View {
        RelayDetailView(relay: relay)
    }
}
