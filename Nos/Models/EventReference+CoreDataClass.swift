//
//  EventReference+CoreDataClass.swift
//  Nos
//
//  Created by Shane Bielefeld on 2/22/23.
//

import Foundation
import CoreData

@objc(EventReference)
public class EventReference: NosManagedObject {
    
    var jsonRepresentation: [String] {
        ["e", eventId ?? "", recommendedRelayUrl ?? "", marker ?? ""]
    }
}
