import Foundation
import CoreData

extension Event {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Event> {
        NSFetchRequest<Event>(entityName: "Event")
    }

    @NSManaged public var allTags: NSObject?
    @NSManaged public var content: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var expirationDate: Date?
    @NSManaged public var identifier: RawEventID?
    @NSManaged public var isVerified: Bool
    @NSManaged public var kind: Int64
    @NSManaged public var receivedAt: Date?
    @NSManaged public var replaceableIdentifier: String?
    @NSManaged public var sendAttempts: Int16
    @NSManaged public var signature: String?
    @NSManaged public var author: Author?
    @NSManaged public var authorReferences: NSOrderedSet
    @NSManaged public var deletedOn: Set<Relay>
    @NSManaged public var eventReferences: NSOrderedSet
    @NSManaged public var publishedTo: Set<Relay>
    @NSManaged public var referencingEvents: Set<EventReference>
    @NSManaged public var seenOnRelays: Set<Relay>
    @NSManaged public var shouldBePublishedTo: Set<Relay>
    @NSManaged public var isRead: Bool
    @NSManaged public var notifications: NosNotification?
}

// MARK: Generated accessors for authorReferences
extension Event {

    @objc(insertObject:inAuthorReferencesAtIndex:)
    @NSManaged public func insertIntoAuthorReferences(_ value: AuthorReference, at idx: Int)

    @objc(removeObjectFromAuthorReferencesAtIndex:)
    @NSManaged public func removeFromAuthorReferences(at idx: Int)

    @objc(insertAuthorReferences:atIndexes:)
    @NSManaged public func insertIntoAuthorReferences(_ values: [AuthorReference], at indexes: NSIndexSet)

    @objc(removeAuthorReferencesAtIndexes:)
    @NSManaged public func removeFromAuthorReferences(at indexes: NSIndexSet)

    @objc(replaceObjectInAuthorReferencesAtIndex:withObject:)
    @NSManaged public func replaceAuthorReferences(at idx: Int, with value: AuthorReference)

    @objc(replaceAuthorReferencesAtIndexes:withAuthorReferences:)
    @NSManaged public func replaceAuthorReferences(at indexes: NSIndexSet, with values: [AuthorReference])

    @objc(addAuthorReferencesObject:)
    @NSManaged public func addToAuthorReferences(_ value: AuthorReference)

    @objc(removeAuthorReferencesObject:)
    @NSManaged public func removeFromAuthorReferences(_ value: AuthorReference)

    @objc(addAuthorReferences:)
    @NSManaged public func addToAuthorReferences(_ values: NSOrderedSet)

    @objc(removeAuthorReferences:)
    @NSManaged public func removeFromAuthorReferences(_ values: NSOrderedSet)
}

// MARK: Generated accessors for deletedOn
extension Event {

    @objc(addDeletedOnObject:)
    @NSManaged public func addToDeletedOn(_ value: Relay)

    @objc(removeDeletedOnObject:)
    @NSManaged public func removeFromDeletedOn(_ value: Relay)

    @objc(addDeletedOn:)
    @NSManaged public func addToDeletedOn(_ values: NSSet)

    @objc(removeDeletedOn:)
    @NSManaged public func removeFromDeletedOn(_ values: NSSet)
}

// MARK: Generated accessors for eventReferences
extension Event {

    @objc(insertObject:inEventReferencesAtIndex:)
    @NSManaged public func insertIntoEventReferences(_ value: EventReference, at idx: Int)

    @objc(removeObjectFromEventReferencesAtIndex:)
    @NSManaged public func removeFromEventReferences(at idx: Int)

    @objc(insertEventReferences:atIndexes:)
    @NSManaged public func insertIntoEventReferences(_ values: [EventReference], at indexes: NSIndexSet)

    @objc(removeEventReferencesAtIndexes:)
    @NSManaged public func removeFromEventReferences(at indexes: NSIndexSet)

    @objc(replaceObjectInEventReferencesAtIndex:withObject:)
    @NSManaged public func replaceEventReferences(at idx: Int, with value: EventReference)

    @objc(replaceEventReferencesAtIndexes:withEventReferences:)
    @NSManaged public func replaceEventReferences(at indexes: NSIndexSet, with values: [EventReference])

    @objc(addEventReferencesObject:)
    @NSManaged public func addToEventReferences(_ value: EventReference)

    @objc(removeEventReferencesObject:)
    @NSManaged public func removeFromEventReferences(_ value: EventReference)

    @objc(addEventReferences:)
    @NSManaged public func addToEventReferences(_ values: NSOrderedSet)

    @objc(removeEventReferences:)
    @NSManaged public func removeFromEventReferences(_ values: NSOrderedSet)
}

// MARK: Generated accessors for publishedTo
extension Event {

    @objc(addPublishedToObject:)
    @NSManaged public func addToPublishedTo(_ value: Relay)

    @objc(removePublishedToObject:)
    @NSManaged public func removeFromPublishedTo(_ value: Relay)

    @objc(addPublishedTo:)
    @NSManaged public func addToPublishedTo(_ values: NSSet)

    @objc(removePublishedTo:)
    @NSManaged public func removeFromPublishedTo(_ values: NSSet)
}

// MARK: Generated accessors for referencingEvents
extension Event {

    @objc(addReferencingEventsObject:)
    @NSManaged public func addToReferencingEvents(_ value: EventReference)

    @objc(removeReferencingEventsObject:)
    @NSManaged public func removeFromReferencingEvents(_ value: EventReference)

    @objc(addReferencingEvents:)
    @NSManaged public func addToReferencingEvents(_ values: NSSet)

    @objc(removeReferencingEvents:)
    @NSManaged public func removeFromReferencingEvents(_ values: NSSet)
}

// MARK: Generated accessors for seenOnRelays
extension Event {

    @objc(addSeenOnRelaysObject:)
    @NSManaged public func addToSeenOnRelays(_ value: Relay)

    @objc(removeSeenOnRelaysObject:)
    @NSManaged public func removeFromSeenOnRelays(_ value: Relay)

    @objc(addSeenOnRelays:)
    @NSManaged public func addToSeenOnRelays(_ values: NSSet)

    @objc(removeSeenOnRelays:)
    @NSManaged public func removeFromSeenOnRelays(_ values: NSSet)
}

// MARK: Generated accessors for shouldBePublishedTo
extension Event {

    @objc(addShouldBePublishedToObject:)
    @NSManaged public func addToShouldBePublishedTo(_ value: Relay)

    @objc(removeShouldBePublishedToObject:)
    @NSManaged public func removeFromShouldBePublishedTo(_ value: Relay)

    @objc(addShouldBePublishedTo:)
    @NSManaged public func addToShouldBePublishedTo(_ values: NSSet)

    @objc(removeShouldBePublishedTo:)
    @NSManaged public func removeFromShouldBePublishedTo(_ values: NSSet)
}

extension Event: Identifiable {}
