//
//  NSSet+Add.swift
//  Nos
//
//  Created by Christopher Jorgensen on 3/14/23.
//

import Foundation
import CoreData

// swiftlint:disable legacy_objc_type
extension NSSet {
    func adding(_ object: NSManagedObject) -> NSSet {
        if let mutableSelf = mutableCopy() as? NSMutableSet {
            mutableSelf.add(object)
            return mutableSelf
        }
        
        return self
    }
    
    func removing(_ object: NSManagedObject) -> NSSet {
        if let mutableSelf = mutableCopy() as? NSMutableSet {
            mutableSelf.remove(object)
            return mutableSelf
        }
        
        return self
    }
}
// swiftlint:enable legacy_objc_type
