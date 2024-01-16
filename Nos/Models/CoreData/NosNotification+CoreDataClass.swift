//
//  NosNotification+CoreDataClass.swift
//  Nos
//
//  Created by Matthew Lorentz on 6/30/23.
//
//

import Foundation
import CoreData

/// Represents a notification we will display to the user. We save records of them to the database in order to 
/// de-duplicate them and keep track of whether they have been seen by the user.
@objc(NosNotification)
public class NosNotification: NSManagedObject {

    class func createIfNecessary(
        from eventID: HexadecimalString, 
        authorKey: HexadecimalString, 
        in context: NSManagedObjectContext
    ) throws -> NosNotification? {
        let author = try Author.findOrCreate(by: authorKey, context: context)
        if try NosNotification.find(by: eventID, in: context) != nil {
            return nil
        } else {
            let notification = NosNotification(context: context)
            notification.eventID = eventID
            notification.user = author
            return notification
        }
    }
    
    class func find(by eventID: HexadecimalString, in context: NSManagedObjectContext) throws -> NosNotification? {
        let fetchRequest = request(by: eventID)
        if let notification = try context.fetch(fetchRequest).first {
            return notification
        }
        
        return nil
    }
    
    class func request(by eventID: HexadecimalString) -> NSFetchRequest<NosNotification> {
        let fetchRequest = NSFetchRequest<NosNotification>(entityName: String(describing: NosNotification.self))
        fetchRequest.predicate = NSPredicate(format: "eventID = %@", eventID)
        fetchRequest.fetchLimit = 1
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \NosNotification.eventID, ascending: false)]
        return fetchRequest
    }
    
    class func unreadCount(for user: Author, in context: NSManagedObjectContext) throws -> Int {
        let fetchRequest = NSFetchRequest<NosNotification>(entityName: String(describing: NosNotification.self))
        fetchRequest.predicate = NSPredicate(format: "isRead != 1")
        return try context.count(for: fetchRequest)
    }
    
    class func markRead(eventID: HexadecimalString, in context: NSManagedObjectContext) async {
        await context.perform {
            if let notification = try? find(by: eventID, in: context), 
                !notification.isRead {
                notification.isRead = true
            }
            
            try? context.saveIfNeeded()
        }
    }
    
    class func markAllAsRead(for user: Author, in context: NSManagedObjectContext) async throws {
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
}
