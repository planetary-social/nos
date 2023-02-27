//
//  Tag+CoreDataClass.swift
//  Nos
//
//  Created by Matthew Lorentz on 1/31/23.
//
//

import Foundation
import CoreData

@objc(Tag)
public class Tag: NosManagedObject {
    
    var jsonRepresentation: [String] {
        [[identifier].compactMap { $0 }, (metadata as! [String])].flatMap({ $0 })
    }
    
    class func find(by pubKey: HexadecimalString, context: NSManagedObjectContext) throws -> Tag? {
        let fetchRequest = NSFetchRequest<Tag>(entityName: String(describing: Tag.self))
        fetchRequest.predicate = NSPredicate(format: "identifier = %@", pubKey)
        fetchRequest.fetchLimit = 1
        if let tag = try context.fetch(fetchRequest).first {
            return tag
        }
        
        return nil
    }
    
    class func findOrCreate(by pubKey: HexadecimalString, context: NSManagedObjectContext) throws -> Tag {
        if let tag = try? Tag.find(by: pubKey, context: context) {
            return tag
        } else {
            let tag = Tag(context: context)
            tag.identifier = pubKey
            return tag
        }
    }
}
