//
//  PubKey+CoreDataProperties.swift
//  Nos
//
//  Created by Matthew Lorentz on 1/31/23.
//
//

import Foundation
import CoreData


extension PubKey {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PubKey> {
        return NSFetchRequest<PubKey>(entityName: "PubKey")
    }

    @NSManaged public var hex: String?
    @NSManaged public var events: NSSet?

}

// MARK: Generated accessors for events
extension PubKey {

    @objc(addEventsObject:)
    @NSManaged public func addToEvents(_ value: Event)

    @objc(removeEventsObject:)
    @NSManaged public func removeFromEvents(_ value: Event)

    @objc(addEvents:)
    @NSManaged public func addToEvents(_ values: NSSet)

    @objc(removeEvents:)
    @NSManaged public func removeFromEvents(_ values: NSSet)

}

extension PubKey : Identifiable {

}
