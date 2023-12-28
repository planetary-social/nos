//
//  RelayDetailView.swift
//  Nos
//
//  Created by Martin Dutra on 6/7/23.
//

import SwiftUI

struct RelayDetailView: View {

    var relay: Relay

    func row(title: LocalizedStringResource, value: String) -> some View {
        HStack(alignment: .top) {
            Text("\(String(localized: title)): ")
            Text(value)
                .textSelection(.enabled)
        }
    }
    var body: some View {
        List {
            Section {
                Text(relay.address ?? String(localized: .localizable.error))
                    .textSelection(.enabled)
            } header: {
                Text(.localizable.address)
                    .foregroundColor(.primaryTxt)
                    .fontWeight(.heavy)
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
                    .fontWeight(.heavy)
            } footer: {
                #if DEBUG
                if let date = relay.metadataFetchedAt {
                    Text("\(String(localized: .localizable.fetchedAt)): \(date.distanceString())")
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
            return try Relay(context: previewContext, address: "wss://example.com")
        } catch {
            return Relay(context: previewContext)
        }
    }
    static var previews: some View {
        RelayDetailView(relay: relay)
    }
}
