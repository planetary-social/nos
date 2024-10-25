//
//  Hashtag+CoreDataProperties.swift
//  Nos
//
//  Created by Matthew Lorentz on 10/25/24.
//
//

import Foundation
import CoreData


extension Hashtag {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Hashtag> {
        return NSFetchRequest<Hashtag>(entityName: "Hashtag")
    }

    @NSManaged public var name: String?
    @NSManaged public var events: NSSet?

}

// MARK: Generated accessors for events
extension Hashtag {

    @objc(addEventsObject:)
    @NSManaged public func addToEvents(_ value: Event)

    @objc(removeEventsObject:)
    @NSManaged public func removeFromEvents(_ value: Event)

    @objc(addEvents:)
    @NSManaged public func addToEvents(_ values: NSSet)

    @objc(removeEvents:)
    @NSManaged public func removeFromEvents(_ values: NSSet)

}

extension Hashtag : Identifiable {

}
