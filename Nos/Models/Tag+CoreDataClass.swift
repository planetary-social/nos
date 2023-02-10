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
public class Tag: NosManagedObject {
    
    var jsonRepresentation: [String] {
        [[identifier].compactMap { $0 }, (metadata as! [String])].flatMap({ $0 })
    }
}
