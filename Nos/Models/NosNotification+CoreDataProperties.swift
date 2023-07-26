//
//  NosNotification+CoreDataProperties.swift
//  Nos
//
//  Created by Matthew Lorentz on 6/30/23.
//
//

import Foundation
import CoreData

extension NosNotification {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<NosNotification> {
        NSFetchRequest<NosNotification>(entityName: "NosNotification")
    }

    @NSManaged public var isRead: Bool
    @NSManaged public var eventID: String?
    @NSManaged public var user: Author?
}

extension NosNotification: Identifiable {}
