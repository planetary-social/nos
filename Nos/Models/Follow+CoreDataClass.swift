//
//  Follow+CoreDataClass.swift
//  Nos
//
//  Created by Christopher Jorgensen on 2/15/23.
//

import Foundation
import CoreData

typealias Followed = [Follow]

@objc(Follow)
public class Follow: Tag {
    convenience init(context: NSManagedObjectContext, jsonTag: [String]) {
        self.init(context: context)
        
        identifier = jsonTag[1]
        
        if jsonTag.count > 2 {
            relay = Relay.findOrCreate(by: jsonTag[2], context: context)
        }
        
        if jsonTag.count > 3 {
            petName = jsonTag[3]
        }
    }
    
    override var jsonRepresentation: [String] {
        [
            "p",
            identifier,
            relay?.jsonRepresentation,
            petName
        ].compactMap { $0 }
    }
}
