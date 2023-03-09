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
    static var defaults: [String] {
        [
        "wss://relay.nostr.band",
        "wss://relay.damus.io",
        "wss://e.nos.lol"
        ]
    }
    
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
    
    class func findOrCreate(by address: String, context: NSManagedObjectContext) -> Relay {
        if let existingRelay = try? context.fetch(Relay.relay(by: address)).first {
            return existingRelay
        } else {
            let relay = Relay(context: context, address: address)
            return relay
        }
    }
    
    var jsonRepresentation: String? {
        address
    }
    
    class func all(context: NSManagedObjectContext) -> [Relay] {
        let allRequest = Relay.allRelaysRequest()
        
        do {
            let results = try context.fetch(allRequest)
            return results
        } catch let error as NSError {
            print("Failed to fetch relays. Error: \(error.description)")
            return []
        }
    }
    
    @discardableResult convenience init(context: NSManagedObjectContext, address: String, author: Author? = nil) {
        self.init(context: context)
        self.address = address
        self.createdAt = Date.now
        author?.add(relay: self)
    }
}
