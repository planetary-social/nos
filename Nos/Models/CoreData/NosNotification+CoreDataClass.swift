import Foundation
import CoreData

/// Represents a notification we will display to the user. We save records of them to the database in order to 
/// de-duplicate them and keep track of whether they have been seen by the user.
@objc(NosNotification)
final class NosNotification: NosManagedObject {

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
            notification.eventID = eventID
            notification.user = author
            notification.createdAt = date
            return notification
        }
    }
    
    static func find(by eventID: RawEventID, in context: NSManagedObjectContext) throws -> NosNotification? {
        let fetchRequest = request(by: eventID)
        if let notification = try context.fetch(fetchRequest).first {
            return notification
        }
        
        return nil
    }
    
    static func request(by eventID: RawEventID) -> NSFetchRequest<NosNotification> {
        let fetchRequest = NSFetchRequest<NosNotification>(entityName: String(describing: NosNotification.self))
        fetchRequest.predicate = NSPredicate(format: "eventID = %@", eventID)
        fetchRequest.fetchLimit = 1
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \NosNotification.eventID, ascending: false)]
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
}
