import Foundation
import CoreData

extension NosNotification {
    @NSManaged public var isRead: Bool
    @NSManaged public var eventID: String?
    @NSManaged public var user: Author?
    @NSManaged public var createdAt: Date?
}

extension NosNotification: Identifiable {}
