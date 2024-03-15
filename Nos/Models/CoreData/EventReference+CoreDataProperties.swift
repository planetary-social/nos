import Foundation
import CoreData

extension EventReference {
    @NSManaged public var eventId: String?
    @NSManaged public var marker: String?
    @NSManaged public var recommendedRelayUrl: String?
    @NSManaged public var referencedEvent: Event?
    @NSManaged public var referencingEvent: Event?
}

extension EventReference: Identifiable {}
