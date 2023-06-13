//
//  RelayMetadata+CoreDataProperties.swift
//  Nos
//
//  Created by Martin Dutra on 8/6/23.
//
//

import Foundation
import CoreData

extension RelayMetadata {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<RelayMetadata> {
        NSFetchRequest<RelayMetadata>(entityName: "RelayMetadata")
    }

    @NSManaged public var name: String?
    @NSManaged public var relayDescription: String?
    @NSManaged public var supportedNIPs: [Int]?
    @NSManaged public var pubkey: String?
    @NSManaged public var contact: String?
    @NSManaged public var software: String?
    @NSManaged public var version: String?
    @NSManaged public var relay: Relay?
    @NSManaged public var timestamp: Date
}

extension RelayMetadata: Identifiable { }
