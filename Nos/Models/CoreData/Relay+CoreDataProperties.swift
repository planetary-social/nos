import Foundation
import CoreData

extension Relay {
    @NSManaged public var address: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var authors: Set<Author>
    @NSManaged public var deletedEvents: Set<Event>
    @NSManaged public var events: Set<Event>
    @NSManaged public var publishedEvents: Set<Event>
    @NSManaged public var shouldBePublishedEvents: Set<Event>

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

extension Relay: Identifiable {}
