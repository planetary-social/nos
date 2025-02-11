import Foundation
import CoreData

extension Relay {

    @nonobjc static func fetchRequest() -> NSFetchRequest<Relay> {
        NSFetchRequest<Relay>(entityName: "Relay")
    }

    @NSManaged var address: String?
    @NSManaged var createdAt: Date?
    @NSManaged var authors: Set<Author>
    @NSManaged var deletedEvents: Set<Event>
    @NSManaged var events: Set<Event>
    @NSManaged var publishedEvents: Set<Event>
    @NSManaged var shouldBePublishedEvents: Set<Event>
    /// Whether or not this relay should be visible in the ``FeedPicker``.
    @NSManaged var isFeedEnabled: Bool

    // Metadata
    @NSManaged var name: String?
    @NSManaged var relayDescription: String?
    @NSManaged var supportedNIPs: [Int]?
    @NSManaged var pubkey: String?
    @NSManaged var contact: String?
    @NSManaged var software: String?
    @NSManaged var version: String?
    @NSManaged var metadataFetchedAt: Date?
}

// MARK: Generated accessors for authors
extension Relay {

    @objc(addAuthorsObject:)
    @NSManaged func addToAuthors(_ value: Author)

    @objc(removeAuthorsObject:)
    @NSManaged func removeFromAuthors(_ value: Author)

    @objc(addAuthors:)
    @NSManaged func addToAuthors(_ values: NSSet)

    @objc(removeAuthors:)
    @NSManaged func removeFromAuthors(_ values: NSSet)
}

// MARK: Generated accessors for deletedEvents
extension Relay {

    @objc(addDeletedEventsObject:)
    @NSManaged func addToDeletedEvents(_ value: Event)

    @objc(removeDeletedEventsObject:)
    @NSManaged func removeFromDeletedEvents(_ value: Event)

    @objc(addDeletedEvents:)
    @NSManaged func addToDeletedEvents(_ values: NSSet)

    @objc(removeDeletedEvents:)
    @NSManaged func removeFromDeletedEvents(_ values: NSSet)
}

// MARK: Generated accessors for events
extension Relay {

    @objc(addEventsObject:)
    @NSManaged func addToEvents(_ value: Event)

    @objc(removeEventsObject:)
    @NSManaged func removeFromEvents(_ value: Event)

    @objc(addEvents:)
    @NSManaged func addToEvents(_ values: NSSet)

    @objc(removeEvents:)
    @NSManaged func removeFromEvents(_ values: NSSet)
}

// MARK: Generated accessors for publishedEvents
extension Relay {

    @objc(addPublishedEventsObject:)
    @NSManaged func addToPublishedEvents(_ value: Event)

    @objc(removePublishedEventsObject:)
    @NSManaged func removeFromPublishedEvents(_ value: Event)

    @objc(addPublishedEvents:)
    @NSManaged func addToPublishedEvents(_ values: NSSet)

    @objc(removePublishedEvents:)
    @NSManaged func removeFromPublishedEvents(_ values: NSSet)
}

extension Relay: Identifiable {}
