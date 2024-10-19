import SwiftUI

struct RelayDetailView: View {

    let relay: Relay

    func row(title: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text("\(title): ")
            Text(value)
                .textSelection(.enabled)
        }
        .font(.clarity(.regular))
    }
    var body: some View {
        List {
            Section {
                Text(relay.address ?? String(localized: "error"))
                    .font(.clarity(.regular))
                    .textSelection(.enabled)
            } header: {
                Text("address")
                    .foregroundColor(.primaryTxt)
                    .font(.clarity(.bold))
            }
            .listRowGradientBackground()
            Section {
                if let name = relay.name {
                    row(title: String(localized: "name"), value: name)
                }
                if let description = relay.relayDescription {
                    row(title: String(localized: "description"), value: description)
                }
                if let supportedNIPs = relay.supportedNIPs {
                    row(
                        title: String(localized: "supportedNIPs"),
                        value: supportedNIPs.map { String($0) }.joined(separator: ", ")
                    )
                }
                if let pubkey = relay.pubkey {
                    row(title: String(localized: "pubkey"), value: pubkey)
                }
                if let contact = relay.contact {
                    row(title: String(localized: "contact"), value: contact)
                }
                if let software = relay.software {
                    row(title: String(localized: "software"), value: software)
                }
                if let version = relay.version {
                    row(title: String(localized: "version"), value: version)
                }
            } header: {
                Text("metadata")
                    .foregroundColor(.primaryTxt)
                    .font(.clarity(.bold))
            } footer: {
                #if DEBUG
                if let date = relay.metadataFetchedAt {
                    Text("\(String(localized: "fetchedAt")): \(date.distanceString())")
                        .font(.clarity(.regular))
                }
                #endif
            }
            .listRowGradientBackground()
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBg)
        .nosNavigationBar("relay")
    }
}

struct RelayDetailView_Previews: PreviewProvider {
    static var previewContext = PersistenceController.preview.viewContext
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
