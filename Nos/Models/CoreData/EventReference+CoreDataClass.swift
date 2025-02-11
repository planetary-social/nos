import Foundation
import CoreData

/// Tag markers for event references that describe what type of reference this is. 
/// See [NIP-10](https://github.com/nostr-protocol/nips/blob/master/10.md)
enum EventReferenceMarker: String {
    
    /// Marks the event being replied to.
    case reply
    
    /// Marks the event at the root of the reply chain. 
    case root
    
    /// Marks a quoted or reposted event.
    case mention
}

@objc(EventReference)
final class EventReference: NosManagedObject {
    
    var type: EventReferenceMarker? {
        marker.unwrap { EventReferenceMarker(rawValue: $0) }
    }
    
    /// Retreives all the EventReferences 
    static func all() -> NSFetchRequest<EventReference> {
        let fetchRequest = NSFetchRequest<EventReference>(entityName: "EventReference")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \EventReference.eventId, ascending: false)]
        return fetchRequest
    }
    
    /// This fetches all the references that can be deleted during the `DatabaseCleaner` routine. It takes care
    /// to only select references before a given date that are not referenced by events we are keeping, and it also
    /// accounts for "protected events" from `Event.protectedFromCleanupPredicate(...)` to make sure we keep 
    /// events published by the current user etc.
    static func cleanupRequest(before date: Date, user: Author) -> NSFetchRequest<EventReference> {
        let fetchRequest = NSFetchRequest<EventReference>(entityName: "EventReference")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \EventReference.eventId, ascending: false)]
        let protectedEventsPredicate = Event.protectedFromCleanupPredicate(for: user, asSubquery: true)
        let referencedEventIsNotProtected = NSPredicate(
            format: "SUBQUERY(referencedEvent, $event,  \(protectedEventsPredicate.predicateFormat)).@count == 0"
        )
        let referencingEventIsNotProtected = NSPredicate(
            format: "SUBQUERY(referencingEvent, $event, \(protectedEventsPredicate.predicateFormat)).@count == 0"
        )
        let eventsAreOld = NSPredicate(
            format: "referencedEvent.receivedAt < %@ AND referencingEvent.receivedAt < %@",
            date as CVarArg,
            date as CVarArg
        )
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            referencedEventIsNotProtected,
            referencingEventIsNotProtected,
            eventsAreOld
        ])
        
        return fetchRequest
    }
    
    /// Retreives all the EventReferences whose referencing Event has been deleted.
    static func orphanedRequest() -> NSFetchRequest<EventReference> {
        let fetchRequest = NSFetchRequest<EventReference>(entityName: "EventReference")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \EventReference.eventId, ascending: false)]
        fetchRequest.predicate = NSPredicate(format: "referencingEvent = nil")
        return fetchRequest
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
