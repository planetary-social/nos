//
//  NSManagedObject+Nos.swift
//  Nos
//
//  Created by Matthew Lorentz on 2/9/23.
//

import CoreData

public class NosManagedObject: NSManagedObject {
    
    // Not sure why this is necessary, but SwiftUI previews crash on NSManagedObject.init(context:) otherwise.
    convenience init(context: NSManagedObjectContext) {
        self.init(entity: Self.entityDescription(in: context), insertInto: context)
    }
    
    class func entityDescription(in context: NSManagedObjectContext) -> NSEntityDescription {
        return NSEntityDescription.entity(forEntityName: String(describing: Self.self), in: context)!
    }
}

