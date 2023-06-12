//
//  Follow+CoreDataProperties.swift
//  Nos
//
//  Created by Matthew Lorentz on 6/8/23.
//
//

import Foundation
import CoreData

extension Follow {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Follow> {
        NSFetchRequest<Follow>(entityName: "Follow")
    }

    @NSManaged public var petName: String?
    @NSManaged public var destination: Author?
    @NSManaged public var source: Author?
}

extension Follow: Identifiable {}
