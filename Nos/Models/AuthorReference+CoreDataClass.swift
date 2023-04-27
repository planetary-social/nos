//
//  AuthorReference+CoreDataClass.swift
//  Nos
//
//  Created by Shane Bielefeld on 2/24/23.
//

import Foundation
import CoreData

@objc(AuthorReference)
public class AuthorReference: NosManagedObject {
    
    var jsonRepresentation: [String] {
        ["p", pubkey ?? ""]
    }
    
    static func orphanedRequest() -> NSFetchRequest<AuthorReference> {
        let fetchRequest = NSFetchRequest<AuthorReference>(entityName: "AuthorReference")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \AuthorReference.pubkey, ascending: false)]
        fetchRequest.predicate = NSPredicate(format: "event = nil")
        return fetchRequest
    }
}
