//
//  Author+CoreDataClass.swift
//  Nos
//
//  Created by Matthew Lorentz on 1/31/23.
//
//

import Foundation
import CoreData

@objc(Author)
public class Author: NosManagedObject {
    
    var npubString: String? {
        publicKey?.npub
    }
    
    var safeName: String {
        displayName ?? name ?? npubString?.prefix(10).appending("...") ?? hexadecimalPublicKey ?? "error"
    }
    
    var publicKey: PublicKey? {
        guard let hex = hexadecimalPublicKey else {
            return nil
        }
        
        return PublicKey(hex: hex)
    }
    
    var needsMetadata: Bool {
        // TODO: consider checking lastUpdated time as an optimization.
        about == nil && name == nil && displayName == nil && profilePhotoURL == nil
    }
    
    class func find(by pubKey: HexadecimalString, context: NSManagedObjectContext) throws -> Author? {
        let fetchRequest = NSFetchRequest<Author>(entityName: String(describing: Author.self))
        fetchRequest.predicate = NSPredicate(format: "hexadecimalPublicKey = %@", pubKey)
        fetchRequest.fetchLimit = 1
        if let author = try context.fetch(fetchRequest).first {
            return author
        }
        
        return nil
    }
    
    class func findOrCreate(by pubKey: HexadecimalString, context: NSManagedObjectContext) throws -> Author {
        if let author = try? Author.find(by: pubKey, context: context) {
            return author
        } else {
            let author = Author(context: context)
            author.hexadecimalPublicKey = pubKey
            return author
        }
    }
    
    @nonobjc public class func allAuthorsRequest() -> NSFetchRequest<Author> {
        let fetchRequest = NSFetchRequest<Author>(entityName: "Author")
        return fetchRequest
    }
    
    @nonobjc func allPostsRequest(_ eventKind: EventKind = .text) -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.createdAt, ascending: false)]
        fetchRequest.predicate = NSPredicate(format: "kind = %i AND author = %@", eventKind.rawValue, self)
        return fetchRequest
    }
    
    class func all(context: NSManagedObjectContext) -> [Author] {
        let allRequest = Author.allAuthorsRequest()
        
        do {
            let results = try context.fetch(allRequest)
            return results
        } catch let error as NSError {
            print("Failed to fetch authors. Error: \(error.description)")
            return []
        }
    }
    
    func add(relay: Relay) {
        if let currentRelays = relays?.mutableCopy() as? NSMutableSet {
            currentRelays.add(relay)
            relays = currentRelays
            
            print("Adding \(relay.address ?? "") to \(hexadecimalPublicKey ?? "")")
        }
    }
    
    func remove(relay: Relay) {
        if let currentRelays = relays?.mutableCopy() as? NSMutableSet {
            currentRelays.remove(relay)
            relays = currentRelays
            
            print("Removed \(relay.address ?? "") from \(hexadecimalPublicKey ?? "")")
        }
    }
    
    func requestMetadata(using relayService: RelayService) -> String? {
        guard let hexadecimalPublicKey else {
            return nil
        }
        
        // TODO: make sure this subscription gets closed if there is no new metadata, or no metadata at all for this
        // user.
        let metaFilter = Filter(authorKeys: [hexadecimalPublicKey], kinds: [.metaData], limit: 1)
        let metaSub = relayService.requestEventsFromAll(filter: metaFilter)
        return metaSub
    }
}
