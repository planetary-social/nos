//
//  Follow+CoreDataClass.swift
//  Nos
//
//  Created by Christopher Jorgensen on 2/15/23.
//

import Foundation
import CoreData

@objc(Follow)
public class Follow: Tag {
    convenience init(context: NSManagedObjectContext, jsonTag: [String]) {
        self.init(context: context)
        
        identifier = jsonTag[1]
        
        if jsonTag.count > 2 {
            if let existingRelay = try? context.fetch(Relay.relay(by: jsonTag[2])).first {
                relay = existingRelay
            } else {
                relay = Relay(context: context)
                relay?.address = jsonTag[2]
            }
        }
        
        if jsonTag.count > 3 {
            petName = jsonTag[3]
        }
    }
}
