import Foundation
import CoreData

extension Event {

    @nonobjc class func fetchRequest() -> NSFetchRequest<Event> {
        NSFetchRequest<Event>(entityName: "Event")
    }

    @NSManaged var allTags: NSObject?
    @NSManaged var content: String?
    @NSManaged var createdAt: Date?
    @NSManaged var expirationDate: Date?
    @NSManaged var identifier: RawEventID?
    @NSManaged var isVerified: Bool
    @NSManaged var kind: Int64
    @NSManaged var receivedAt: Date?
    @NSManaged var replaceableIdentifier: String?
    @NSManaged var sendAttempts: Int16
    @NSManaged var signature: String?
    @NSManaged var author: Author?
    @NSManaged var authorReferences: NSOrderedSet
    @NSManaged var deletedOn: Set<Relay>
    @NSManaged var eventReferences: NSOrderedSet
    @NSManaged var publishedTo: Set<Relay>
    @NSManaged var referencingEvents: Set<EventReference>
    @NSManaged var seenOnRelays: Set<Relay>
    @NSManaged var shouldBePublishedTo: Set<Relay>
    @NSManaged var isRead: Bool
}

// MARK: Generated accessors for authorReferences
extension Event {

    @objc(insertObject:inAuthorReferencesAtIndex:)
    @NSManaged func insertIntoAuthorReferences(_ value: AuthorReference, at idx: Int)

    @objc(removeObjectFromAuthorReferencesAtIndex:)
    @NSManaged func removeFromAuthorReferences(at idx: Int)

    @objc(insertAuthorReferences:atIndexes:)
    @NSManaged func insertIntoAuthorReferences(_ values: [AuthorReference], at indexes: NSIndexSet)

    @objc(removeAuthorReferencesAtIndexes:)
    @NSManaged func removeFromAuthorReferences(at indexes: NSIndexSet)

    @objc(replaceObjectInAuthorReferencesAtIndex:withObject:)
    @NSManaged func replaceAuthorReferences(at idx: Int, with value: AuthorReference)

    @objc(replaceAuthorReferencesAtIndexes:withAuthorReferences:)
    @NSManaged func replaceAuthorReferences(at indexes: NSIndexSet, with values: [AuthorReference])

    @objc(addAuthorReferencesObject:)
    @NSManaged func addToAuthorReferences(_ value: AuthorReference)

    @objc(removeAuthorReferencesObject:)
    @NSManaged func removeFromAuthorReferences(_ value: AuthorReference)

    @objc(addAuthorReferences:)
    @NSManaged func addToAuthorReferences(_ values: NSOrderedSet)

    @objc(removeAuthorReferences:)
    @NSManaged func removeFromAuthorReferences(_ values: NSOrderedSet)
}

// MARK: Generated accessors for deletedOn
extension Event {

    @objc(addDeletedOnObject:)
    @NSManaged func addToDeletedOn(_ value: Relay)

    @objc(removeDeletedOnObject:)
    @NSManaged func removeFromDeletedOn(_ value: Relay)

    @objc(addDeletedOn:)
    @NSManaged func addToDeletedOn(_ values: NSSet)

    @objc(removeDeletedOn:)
    @NSManaged func removeFromDeletedOn(_ values: NSSet)
}

// MARK: Generated accessors for eventReferences
extension Event {

    @objc(insertObject:inEventReferencesAtIndex:)
    @NSManaged func insertIntoEventReferences(_ value: EventReference, at idx: Int)

    @objc(removeObjectFromEventReferencesAtIndex:)
    @NSManaged func removeFromEventReferences(at idx: Int)

    @objc(insertEventReferences:atIndexes:)
    @NSManaged func insertIntoEventReferences(_ values: [EventReference], at indexes: NSIndexSet)

    @objc(removeEventReferencesAtIndexes:)
    @NSManaged func removeFromEventReferences(at indexes: NSIndexSet)

    @objc(replaceObjectInEventReferencesAtIndex:withObject:)
    @NSManaged func replaceEventReferences(at idx: Int, with value: EventReference)

    @objc(replaceEventReferencesAtIndexes:withEventReferences:)
    @NSManaged func replaceEventReferences(at indexes: NSIndexSet, with values: [EventReference])

    @objc(addEventReferencesObject:)
    @NSManaged func addToEventReferences(_ value: EventReference)

    @objc(removeEventReferencesObject:)
    @NSManaged func removeFromEventReferences(_ value: EventReference)

    @objc(addEventReferences:)
    @NSManaged func addToEventReferences(_ values: NSOrderedSet)

    @objc(removeEventReferences:)
    @NSManaged func removeFromEventReferences(_ values: NSOrderedSet)
}

// MARK: Generated accessors for publishedTo
extension Event {

    @objc(addPublishedToObject:)
    @NSManaged func addToPublishedTo(_ value: Relay)

    @objc(removePublishedToObject:)
    @NSManaged func removeFromPublishedTo(_ value: Relay)

    @objc(addPublishedTo:)
    @NSManaged func addToPublishedTo(_ values: NSSet)

    @objc(removePublishedTo:)
    @NSManaged func removeFromPublishedTo(_ values: NSSet)
}

// MARK: Generated accessors for referencingEvents
extension Event {

    @objc(addReferencingEventsObject:)
    @NSManaged func addToReferencingEvents(_ value: EventReference)

    @objc(removeReferencingEventsObject:)
    @NSManaged func removeFromReferencingEvents(_ value: EventReference)

    @objc(addReferencingEvents:)
    @NSManaged func addToReferencingEvents(_ values: NSSet)

    @objc(removeReferencingEvents:)
    @NSManaged func removeFromReferencingEvents(_ values: NSSet)
}

// MARK: Generated accessors for seenOnRelays
extension Event {

    @objc(addSeenOnRelaysObject:)
    @NSManaged func addToSeenOnRelays(_ value: Relay)

    @objc(removeSeenOnRelaysObject:)
    @NSManaged func removeFromSeenOnRelays(_ value: Relay)

    @objc(addSeenOnRelays:)
    @NSManaged func addToSeenOnRelays(_ values: NSSet)

    @objc(removeSeenOnRelays:)
    @NSManaged func removeFromSeenOnRelays(_ values: NSSet)
}

// MARK: Generated accessors for shouldBePublishedTo
extension Event {

    @objc(addShouldBePublishedToObject:)
    @NSManaged func addToShouldBePublishedTo(_ value: Relay)

    @objc(removeShouldBePublishedToObject:)
    @NSManaged func removeFromShouldBePublishedTo(_ value: Relay)

    @objc(addShouldBePublishedTo:)
    @NSManaged func addToShouldBePublishedTo(_ values: NSSet)

    @objc(removeShouldBePublishedTo:)
    @NSManaged func removeFromShouldBePublishedTo(_ values: NSSet)
}

extension Event: Identifiable {}
