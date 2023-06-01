//
//  RelayMetadata+CoreDataClass.swift
//  Nos
//
//  Created by Martin Dutra on 1/6/23.
//
//

import Foundation
import CoreData

@objc(RelayMetadata)
public class RelayMetadata: NosManagedObject {
    @NSManaged public var name: String
    @NSManaged public var relayDescription: String
    @NSManaged public var supportedNIPs: [Int]
    @NSManaged public var relay: Relay?
}
