//
//  ETag+CoreDataClass.swift
//  Nos
//
//  Created by Shane Bielefeld on 2/22/23.
//

import Foundation
import CoreData

@objc(ETag)
public class ETag: NosManagedObject {
    
    var jsonRepresentation: [String] {
        ["e", eventId ?? "", recommendedRelayUrl ?? "", marker ?? ""]
    }
}
