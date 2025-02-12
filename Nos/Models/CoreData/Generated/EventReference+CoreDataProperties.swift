import Foundation
import CoreData

extension EventReference {

    @nonobjc static func fetchRequest() -> NSFetchRequest<EventReference> {
        NSFetchRequest<EventReference>(entityName: "EventReference")
    }

    @NSManaged var eventId: String?
    @NSManaged var marker: String?
    @NSManaged var recommendedRelayUrl: String?
    @NSManaged var referencedEvent: Event?
    @NSManaged var referencingEvent: Event?
}

extension EventReference: Identifiable {}
