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
}
