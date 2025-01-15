import Foundation
import CoreData

extension NosNotification {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<NosNotification> {
        NSFetchRequest<NosNotification>(entityName: "NosNotification")
    }

    @NSManaged public var isRead: Bool
    @NSManaged public var user: Author?
    @NSManaged public var follower: Author?
    @NSManaged public var createdAt: Date?
    @NSManaged public var event: Event?
}

extension NosNotification: Identifiable {}
