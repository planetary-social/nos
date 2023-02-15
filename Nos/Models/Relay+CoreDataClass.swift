//
//  Relay+CoreDataClass.swift
//  Nos
//
//  Created by Matthew Lorentz on 1/31/23.
//
//

import Foundation
import CoreData

@objc(Relay)
public class Relay: NosManagedObject {
    @nonobjc public class func allRelaysRequest() -> NSFetchRequest<Relay> {
        let fetchRequest = NSFetchRequest<Relay>(entityName: "Relay")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Relay.address, ascending: true)]
        return fetchRequest
    }
    
    @nonobjc public class func relay(by address: String) -> NSFetchRequest<Relay> {
        let fetchRequest = NSFetchRequest<Relay>(entityName: "Relay")
        fetchRequest.predicate = NSPredicate(format: "address = %@", address)
        fetchRequest.fetchLimit = 1
        return fetchRequest
    }
}
