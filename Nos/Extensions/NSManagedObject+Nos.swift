//
//  NSManagedObject+Nos.swift
//  Nos
//
//  Created by Matthew Lorentz on 2/9/23.
//

import CoreData
import Logger

public class NosManagedObject: NSManagedObject {
    
    class func entityDescription(in context: NSManagedObjectContext) -> NSEntityDescription {
        if let entity = NSEntityDescription.entity(forEntityName: String(describing: Self.self), in: context) {
            return entity
        } else {
            Log.error("Couldn't create entity description")
            return NSEntityDescription()
        }
    }
}
