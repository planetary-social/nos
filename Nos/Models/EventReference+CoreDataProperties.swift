//
//  EventReference+CoreDataProperties.swift
//  Nos
//
//  Created by Matthew Lorentz on 6/8/23.
//
//

import Foundation
import CoreData

extension EventReference {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<EventReference> {
        NSFetchRequest<EventReference>(entityName: "EventReference")
    }

    @NSManaged public var eventId: String?
    @NSManaged public var marker: String?
    @NSManaged public var recommendedRelayUrl: String?
    @NSManaged public var referencedEvent: Event?
    @NSManaged public var referencingEvent: Event?
}

extension EventReference: Identifiable {}


