import Foundation
import CoreData

extension NosNotification {

    @nonobjc static func fetchRequest() -> NSFetchRequest<NosNotification> {
        NSFetchRequest<NosNotification>(entityName: "NosNotification")
    }

    @NSManaged var isRead: Bool
    @NSManaged var eventID: String?
    @NSManaged var user: Author?
    @NSManaged var follower: Author?
    @NSManaged var createdAt: Date?
}

extension NosNotification: Identifiable {}
