//
//  RelayMetadata+CoreDataClass.swift
//  Nos
//
//  Created by Martin Dutra on 8/6/23.
//
//

import Foundation
import CoreData

public class RelayMetadata: NosManagedObject {

    convenience init(context: NSManagedObjectContext, jsonRelayMetadata: JSONRelayMetadata) throws {
        self.init(context: context)
        try hydrate(from: jsonRelayMetadata)
        timestamp = Date.now
    }

    override public var description: String {
        var attributes = [String]()
        if let name {
            attributes.append("Name: \(name)")
        }
        if let relayDescription {
            attributes.append("Description: \(relayDescription)")
        }
        if let supportedNIPs {
            attributes.append("Supported NIPs: \(supportedNIPs.map { String($0) }.joined(separator: ", "))")
        }
        if let pubkey {
            attributes.append("PubKey: \(pubkey.prefix(7))")
        }
        if let contact {
            attributes.append("Contact: \(contact.prefix(7))")
        }
        if let software {
            attributes.append("Software: \(software)")
        }
        if let version {
            attributes.append("Version: \(version)")
        }
        return attributes.joined(separator: "\n")
    }

    /// Populates metadata using the data in the given JSON.
    func hydrate(from jsonMetadata: JSONRelayMetadata) throws {
        name = jsonMetadata.name
        relayDescription = jsonMetadata.description
        supportedNIPs = jsonMetadata.supportedNIPs
        pubkey = jsonMetadata.pubkey
        contact = jsonMetadata.contact
        software = jsonMetadata.software
        version = jsonMetadata.version
    }
}
