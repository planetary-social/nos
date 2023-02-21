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
    
    var displayName: String {
        name ?? npubString?.prefix(10).appending("...") ?? hexadecimalPublicKey ?? "error"
    }
    
    var isPopulated: Bool {
        let hasName = (name != nil)
        let hasAbout = (about != nil)
        let hasPhoto = (profilePhotoURL != nil)
        
        return hasName || hasAbout || hasPhoto
    }
    
    var publicKey: PublicKey? {
        guard let hex = hexadecimalPublicKey else {
            return nil
        }
        
        return PublicKey(hex: hex)
    }
    
    class func findOrCreate(by pubKey: HexadecimalString, context: NSManagedObjectContext) throws -> Author {
        let fetchRequest = NSFetchRequest<Author>(entityName: String(describing: Author.self))
        fetchRequest.predicate = NSPredicate(format: "hexadecimalPublicKey = %@", pubKey)
        fetchRequest.fetchLimit = 1
        if let author = try context.fetch(fetchRequest).first {
            return author
        } else {
            let author = Author(context: context)
            author.hexadecimalPublicKey = pubKey
            return author
        }
    }
    
    @nonobjc func allPostsRequest(_ eventKind: EventKind = .text) -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.createdAt, ascending: false)]
        fetchRequest.predicate = NSPredicate(format: "kind = %i AND author = %@", eventKind.rawValue, self)
        return fetchRequest
    }
}
