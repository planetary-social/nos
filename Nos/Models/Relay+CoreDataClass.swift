//
//  Relay+CoreDataClass.swift
//  Nos
//
//  Created by Matthew Lorentz on 1/31/23.
//
//

import Foundation
import CoreData

enum RelayError: Error {
    case invalidAddress
    case parseError
}

@objc(Relay)
public class Relay: NosManagedObject {
    static var recommended: [String] {
        [
        "wss://relay.nostr.band/",
        "wss://relay.damus.io/",
        "wss://e.nos.lol/",
        "wss://nostr-dev.universalname.space",
        ]
    }
    
    static var allKnown: [String] {
        [
        "wss://eden.nostr.land/",
        "wss://nostr.fmt.wiz.biz/",
        "wss://relay.damus.io/",
        "wss://nostr-pub.wellorder.net/",
        "wss://relay.nostr.info/",
        "wss://offchain.pub/",
        "wss://nos.lol/",
        "wss://brb.io/",
        "wss://relay.snort.social/",
        "wss://relay.current.fyi/",
        "wss://nostr.relayer.se/",
        "wss://e.nos.lol/",
        "wss://relay.universalname.space",
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
    
    @nonobjc public class func relays(for user: Author) -> NSFetchRequest<Relay> {
        let fetchRequest = NSFetchRequest<Relay>(entityName: "Relay")
        fetchRequest.predicate = NSPredicate(format: "ANY authors = %@", user)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Relay.address, ascending: true)]
        return fetchRequest
    }
    
    @nonobjc public class func emptyRequest() -> NSFetchRequest<Relay> {
        let fetchRequest = NSFetchRequest<Relay>(entityName: "Relay")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Relay.createdAt, ascending: true)]
        fetchRequest.predicate = NSPredicate.false
        return fetchRequest
    }
    
    /// Retreives all the Relays that are no longer referenced by anyone in the db.
    static func orphanedRequest() -> NSFetchRequest<Relay> {
        let fetchRequest = NSFetchRequest<Relay>(entityName: "Relay")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Relay.address, ascending: false)]
        fetchRequest.predicate = NSPredicate(
            format: "SUBQUERY(authors, $a, TRUEPREDICATE).@count = 0 AND " +
                "SUBQUERY(deletedEvents, $d, TRUEPREDICATE).@count = 0 AND " +
                "SUBQUERY(events, $e, TRUEPREDICATE).@count = 0 AND " +
                "SUBQUERY(publishedEvents, $e, TRUEPREDICATE).@count = 0 AND " +
                "SUBQUERY(shouldBePublishedEvents, $r, TRUEPREDICATE).@count = 0"
        )
            
        return fetchRequest
    }
    
    @discardableResult
    class func findOrCreate(by address: String, context: NSManagedObjectContext) throws -> Relay {
        if let existingRelay = try context.fetch(Relay.relay(by: address)).first {
            return existingRelay
        } else {
            let relay = try Relay(context: context, address: address)
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
    
    convenience init(context: NSManagedObjectContext, address: String, author: Author? = nil) throws {
        guard let addressURL = URL(string: address),
            addressURL.scheme == "wss" else {
            throw RelayError.invalidAddress
        }
        
        self.init(context: context)
        self.address = addressURL.absoluteString
        self.createdAt = Date.now
        if let author {
            authors.insert(author)
            author.add(relay: self)
        }
    }
    
    var addressURL: URL? {
        if let address {
            return URL(string: address)
        }
        return nil
    }
    
    var host: String? {
        addressURL?.host
    }
}
