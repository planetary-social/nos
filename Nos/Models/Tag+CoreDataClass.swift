//
//  Tag+CoreDataClass.swift
//  Nos
//
//  Created by Matthew Lorentz on 1/31/23.
//
//

import Foundation
import CoreData

@objc(Tag)
public class Tag: NSManagedObject {
    
    var jsonRepresentation: [String] {
        [[identifier].compactMap { $0 }, (metadata as! Array<String>)].flatMap({ $0 })
    }

}
