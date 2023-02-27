//
//  Follow+CoreDataClass.swift
//  Nos
//
//  Created by Christopher Jorgensen on 2/15/23.
//

import Foundation
import CoreData

typealias Followed = [Follow]

@objc(Follow)
public class Follow: Tag {
    convenience init(context: NSManagedObjectContext, jsonTag: [String]) {
        self.init(context: context)
        
        identifier = jsonTag[1]
        
        if jsonTag.count > 2 {
            relay = Relay.findOrCreate(by: jsonTag[2], context: context)
        }
        
        if jsonTag.count > 3 {
            petName = jsonTag[3]
        }
    }
    
    override var jsonRepresentation: [String] {
        [
            "p",
            identifier,
            relay?.jsonRepresentation,
            petName
        ].compactMap { $0 }
    }
    
    override class func find(by pubKey: HexadecimalString, context: NSManagedObjectContext) throws -> Follow? {
        let fetchRequest = NSFetchRequest<Follow>(entityName: String(describing: Follow.self))
        fetchRequest.predicate = NSPredicate(format: "identifier = %@", pubKey)
        fetchRequest.fetchLimit = 1
        if let tag = try context.fetch(fetchRequest).first {
            return tag
        }
        
        return nil
    }
    
    override class func findOrCreate(by pubKey: HexadecimalString, context: NSManagedObjectContext) throws -> Follow {
        if let follow = try? Follow.find(by: pubKey, context: context) {
            return follow
        } else {
            let follow = Follow(context: context)
            follow.identifier = pubKey
            return follow
        }
    }
}
