import Foundation
import CoreData

extension Relay {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Relay> {
        NSFetchRequest<Relay>(entityName: "Relay")
    }

    @NSManaged public var address: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var authors: Set<Author>
    @NSManaged public var deletedEvents: Set<Event>
    @NSManaged public var events: Set<Event>
    @NSManaged public var publishedEvents: Set<Event>
    @NSManaged public var shouldBePublishedEvents: Set<Event>
    /// Whether or not this relay should be visible in the ``FeedPicker``.
    @NSManaged public var isFeedEnabled: Bool

    // Metadata
    @NSManaged public var name: String?
    @NSManaged public var relayDescription: String?
    @NSManaged public var supportedNIPs: [Int]?
    @NSManaged public var pubkey: String?
    @NSManaged public var contact: String?
    @NSManaged public var software: String?
    @NSManaged public var version: String?
    @NSManaged public var metadataFetchedAt: Date?
}

// MARK: Generated accessors for authors
extension Relay {

    @objc(addAuthorsObject:)
    @NSManaged public func addToAuthors(_ value: Author)

    @objc(removeAuthorsObject:)
    @NSManaged public func removeFromAuthors(_ value: Author)

    @objc(addAuthors:)
    @NSManaged public func addToAuthors(_ values: NSSet)

    @objc(removeAuthors:)
    @NSManaged public func removeFromAuthors(_ values: NSSet)
}

// MARK: Generated accessors for deletedEvents
extension Relay {

    @objc(addDeletedEventsObject:)
    @NSManaged public func addToDeletedEvents(_ value: Event)

    @objc(removeDeletedEventsObject:)
    @NSManaged public func removeFromDeletedEvents(_ value: Event)

    @objc(addDeletedEvents:)
    @NSManaged public func addToDeletedEvents(_ values: NSSet)

    @objc(removeDeletedEvents:)
    @NSManaged public func removeFromDeletedEvents(_ values: NSSet)
}

// MARK: Generated accessors for events
extension Relay {

    @objc(addEventsObject:)
    @NSManaged public func addToEvents(_ value: Event)

    @objc(removeEventsObject:)
    @NSManaged public func removeFromEvents(_ value: Event)

    @objc(addEvents:)
    @NSManaged public func addToEvents(_ values: NSSet)

    @objc(removeEvents:)
    @NSManaged public func removeFromEvents(_ values: NSSet)
}

// MARK: Generated accessors for publishedEvents
extension Relay {

    @objc(addPublishedEventsObject:)
    @NSManaged public func addToPublishedEvents(_ value: Event)

    @objc(removePublishedEventsObject:)
    @NSManaged public func removeFromPublishedEvents(_ value: Event)

    @objc(addPublishedEvents:)
    @NSManaged public func addToPublishedEvents(_ values: NSSet)

    @objc(removePublishedEvents:)
    @NSManaged public func removeFromPublishedEvents(_ values: NSSet)
}

extension Relay: Identifiable {}
