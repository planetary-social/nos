import Foundation
import CoreData

/// Represents a notification we will display to the user. We save records of them to the database in order to
/// de-duplicate them and keep track of whether they have been seen by the user.
@objc(NosNotification)
public class NosNotification: NosManagedObject {

    static func createIfNecessary(
        from eventID: RawEventID,
        date: Date,
        authorKey: RawAuthorID,
        in context: NSManagedObjectContext
    ) throws -> NosNotification? {
        guard date > staleNotificationCutoff() else {
            return nil
        }
        let author = try Author.findOrCreate(by: authorKey, context: context)
        if try NosNotification.find(by: eventID, in: context) != nil {
            return nil
        } else {
            let notification = NosNotification(context: context)
            notification.createdAt = date
            notification.user = author
            // Only set follower relationship if this is a follow event
            if let event = Event.find(by: eventID, context: context) {
                notification.event = event
                if event.kind == EventKind.contactList.rawValue {
                    notification.follower = event.author
                }
            }

            return notification
        }
    }

    static func find(by eventID: RawNostrID, in context: NSManagedObjectContext) throws -> NosNotification? {
        let fetchRequest = request(by: eventID)
        if let notification = try context.fetch(fetchRequest).first {
            return notification
        }

        return nil
    }

    static func request(by eventID: RawNostrID) -> NSFetchRequest<NosNotification> {
        let fetchRequest = NSFetchRequest<NosNotification>(entityName: String(describing: NosNotification.self))
        fetchRequest.predicate = NSPredicate(format: "event.identifier = %@", eventID)
        fetchRequest.fetchLimit = 1
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \NosNotification.event, ascending: false)]
        return fetchRequest
    }

    static func unreadCount(in context: NSManagedObjectContext) throws -> Int {
        let fetchRequest = NSFetchRequest<NosNotification>(entityName: String(describing: NosNotification.self))
        fetchRequest.predicate = NSPredicate(format: "isRead != 1")
        return try context.count(for: fetchRequest)
    }

    // TODO: user is unused; is this a bug?
    static func markAllAsRead(in context: NSManagedObjectContext) async throws {
        try await context.perform {
            let fetchRequest = NSFetchRequest<NosNotification>(entityName: String(describing: NosNotification.self))
            fetchRequest.predicate = NSPredicate(format: "isRead != 1")
            let unreadNotifications = try context.fetch(fetchRequest)
            for notification in unreadNotifications {
                notification.isRead = true
            }

            try? context.saveIfNeeded()
        }
    }

    static func oldNotificationsRequest() -> NSFetchRequest<NosNotification> {
        let fetchRequest = NSFetchRequest<NosNotification>(entityName: "NosNotification")
        let since = staleNotificationCutoff()
        fetchRequest.predicate = NSPredicate(format: "createdAt == nil OR createdAt < %@", since as CVarArg)
        return fetchRequest
    }

    /// Two months before Date.now, and is used to delete old notifications from the db.
    static func staleNotificationCutoff() -> Date {
        Calendar.current.date(byAdding: .month, value: -2, to: .now) ?? .now
    }

    @nonobjc public class func emptyRequest() -> NSFetchRequest<NosNotification> {
        let fetchRequest = NSFetchRequest<NosNotification>(entityName: "NosNotification")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \NosNotification.createdAt, ascending: true)]
        fetchRequest.predicate = NSPredicate.false
        return fetchRequest
    }

    /// A request for all notifications that the given user should receive a notification for.
    /// - Parameters:
    ///   - currentUser: the author you want to view notifications for.
    ///   - since: a date that will be used as a lower bound for the request.
    ///   - limit: a max number of notifications to fetch.
    /// - Returns: A fetch request for all notifications.
    @nonobjc public class func allRequest(
        for currentUser: Author,
        since: Date? = nil,
        limit: Int? = nil
    ) -> NSFetchRequest<NosNotification> {
        let fetchRequest = NSFetchRequest<NosNotification>(entityName: "NosNotification")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \NosNotification.createdAt, ascending: false)]
        if let limit {
            fetchRequest.fetchLimit = limit
        }
        return fetchRequest
    }

    /// A request for all follow notifications that the given user should receive.
    /// - Parameters:
    ///   - currentUser: the author you want to view notifications for.
    ///   - limit: a max number of notifications to fetch.
    /// - Returns: A fetch request for follow notifications.
    @nonobjc public class func followsRequest(
        for currentUser: Author,
        limit: Int? = nil
    ) -> NSFetchRequest<NosNotification> {
        let fetchRequest = NSFetchRequest<NosNotification>(entityName: "NosNotification")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \NosNotification.createdAt, ascending: false)]
        if let limit {
            fetchRequest.fetchLimit = limit
        }

        fetchRequest.predicate = NSPredicate(format: "follower != nil")

        return fetchRequest
    }
}

extension NosNotification: NotificationDisplayable {
    /// Returns the follower as the author since they generated the follow notification.
    var author: Author? {
        follower
    }
}
