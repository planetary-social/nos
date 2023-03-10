//
//  EventReference+CoreDataClass.swift
//  Nos
//
//  Created by Shane Bielefeld on 2/22/23.
//

import Foundation
import CoreData

@objc(EventReference)
public class EventReference: NosManagedObject {
    
    var jsonRepresentation: [String] {
        ["e", eventId ?? "", recommendedRelayUrl ?? "", marker ?? ""]
    }
    
    convenience init(jsonTag: [String], context: NSManagedObjectContext) throws {
        guard jsonTag[safe: 0] == "e",
            let eventID = jsonTag[safe: 1] else {
            throw EventError.invalidETag(jsonTag)
        }
        self.init(context: context)
        referencedEvent = try Event.findOrCreateStubBy(id: eventID, context: context)
        eventId = eventID
        recommendedRelayUrl = jsonTag[safe: 2]
        marker = jsonTag[safe: 3]
    }
}
