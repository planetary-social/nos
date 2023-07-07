//
//  RelayDetailView.swift
//  Nos
//
//  Created by Martin Dutra on 6/7/23.
//

import SwiftUI

struct RelayDetailView: View {

    var relay: Relay

    func row(title: Localized, value: String) -> some View {
        HStack(alignment: .top) {
            Text("\(title.string): ")
            Text(value)
        }
    }
    var body: some View {
        List {
            Section {
                Text(relay.address ?? Localized.error.string)
            } header: {
                Localized.address.view
                    .foregroundColor(.textColor)
                    .fontWeight(.heavy)
            }
            .listRowBackground(LinearGradient(
                colors: [Color.cardBgTop, Color.cardBgBottom],
                startPoint: .top,
                endPoint: .bottom
            ))
            Section {
                if let name = relay.name {
                    row(title: .name, value: name)
                }
                if let description = relay.relayDescription {
                    row(title: .description, value: description)
                }
                if let supportedNIPs = relay.supportedNIPs {
                    row(title: .supportedNIPs, value: supportedNIPs.map { String($0) }.joined(separator: ", "))
                }
                if let pubkey = relay.pubkey {
                    row(title: .pubkey, value: pubkey)
                }
                if let contact = relay.contact {
                    row(title: .contact, value: contact)
                }
                if let software = relay.software {
                    row(title: .software, value: software)
                }
                if let version = relay.version {
                    row(title: .version, value: version)
                }
            } header: {
                Localized.metadata.view
                    .foregroundColor(.textColor)
                    .fontWeight(.heavy)
            } footer: {
                #if DEBUG
                if let date = relay.metadataFetchedAt {
                    Text("\(Localized.fetchedAt.string): \(date.elapsedTimeFromNowString())")
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
        .nosNavigationBar(title: .relay)
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
