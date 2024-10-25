//
//  Hashtag+CoreDataClass.swift
//  Nos
//
//  Created by Matthew Lorentz on 10/25/24.
//
//

import Foundation
import CoreData

@objc(Hashtag)
public class Hashtag: NSManagedObject {
    
    @discardableResult
    class func findOrCreate(by name: String, context: NSManagedObjectContext) throws -> Hashtag {
        if let hashtag = try? Hashtag.find(by: name, context: context) {
            return hashtag
        } else {
            let hashtag = Hashtag(context: context)
            hashtag.name = name
            return hashtag
        }
    }
    
    
    class func find(by name: String, context: NSManagedObjectContext) throws -> Hashtag? {
        let fetchRequest = NSFetchRequest<Hashtag>(entityName: String(describing: Hashtag.self))
        fetchRequest.predicate = NSPredicate(format: "name = %@", name)
        fetchRequest.fetchLimit = 1
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Hashtag.name, ascending: false)]
        if let hashtag = try context.fetch(fetchRequest).first {
            return hashtag
        }
        
        return nil
    }

}
