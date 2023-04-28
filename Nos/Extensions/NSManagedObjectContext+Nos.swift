//
//  NSManagedObjectContext+Nos.swift
//  Nos
//
//  Created by Matthew Lorentz on 4/11/23.
//

import Foundation
import CoreData

extension NSManagedObjectContext {
    func saveIfNeeded() throws {
        try performAndWait {
            if hasChanges {
                try save()
            }
        }
    }
}
