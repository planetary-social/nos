import Foundation
import CoreData

extension Event {
    @NSManaged public var allTags: NSObject?
    @NSManaged public var content: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var expirationDate: Date?
    @NSManaged public var identifier: RawEventID?
    @NSManaged public var isVerified: Bool
    @NSManaged public var kind: Int64
    @NSManaged public var receivedAt: Date?
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
}

// MARK: Generated accessors for eventReferences
extension Event {
    @objc(insertObject:inEventReferencesAtIndex:)
    @NSManaged public func insertIntoEventReferences(_ value: EventReference, at idx: Int)

    @objc(addEventReferencesObject:)
    @NSManaged public func addToEventReferences(_ value: EventReference)
}

extension Event: Identifiable {}
