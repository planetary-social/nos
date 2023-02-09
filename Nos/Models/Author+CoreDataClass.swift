//
//  Author+CoreDataClass.swift
//  Nos
//
//  Created by Matthew Lorentz on 1/31/23.
//
//

import Foundation
import CoreData

@objc(Author)
public class Author: NosManagedObject {
    var npubString: String {
        guard let hex = hexadecimalPublicKey else {
            return "error"
        }
        
        let publicKey = PublicKey(hex: hex)
        return publicKey?.npub ?? "error"
    }
}
