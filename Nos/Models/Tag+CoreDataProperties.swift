//
//  Tag+CoreDataProperties.swift
//  Nos
//
//  Created by Matthew Lorentz on 1/31/23.
//
//

import Foundation
import CoreData


extension Tag {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Tag> {
        return NSFetchRequest<Tag>(entityName: "Tag")
    }

    @NSManaged public var identifier: String?
    @NSManaged public var metadata: NSObject?
    @NSManaged public var event: Event?

}

extension Tag : Identifiable {

}
