//
//  Relay+CoreDataProperties.swift
//  Nos
//
//  Created by Matthew Lorentz on 1/31/23.
//
//

import Foundation
import CoreData


extension Relay {

    @nonobjc public class func allRelaysRequest() -> NSFetchRequest<Relay> {
        let fetchRequest = NSFetchRequest<Relay>(entityName: "Relay")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Relay.address, ascending: true)]
        return fetchRequest
    }

    @NSManaged public var address: String?

}

extension Relay : Identifiable {

}
