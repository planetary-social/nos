//
//  NosNotification+CoreDataClass.swift
//  Nos
//
//  Created by Matthew Lorentz on 6/30/23.
//
//

import Foundation
import CoreData

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
}
