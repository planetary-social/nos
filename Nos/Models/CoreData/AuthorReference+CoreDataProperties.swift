//
//  AuthorReference+CoreDataProperties.swift
//  Nos
//
//  Created by Matthew Lorentz on 6/8/23.
//
//

import Foundation
import CoreData

extension AuthorReference {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AuthorReference> {
        NSFetchRequest<AuthorReference>(entityName: "AuthorReference")
    }

    @NSManaged public var pubkey: String?
    @NSManaged public var recommendedRelayUrl: String?
    @NSManaged public var event: Event?
}

extension AuthorReference: Identifiable {}
