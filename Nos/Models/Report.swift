//
//  Report.swift
//  Nos
//
//  Created by Matthew Lorentz on 5/24/23.
//

import Foundation

/// Represents a report of inappropriate content by the user.
struct Report {
    
    /// The object being reported.
    var target: ReportTarget
    
    /// The reason the object is inappropriate.
    var reasons: [ReportCategory]
}

/// The types of objects that can be reported. 
enum ReportTarget {
    
    case note(Event)
    case author(Author)
    
    /// The author who owns the content being reported.
    var author: Author? {
        switch self {
        case .note(let note):
            return note.author
        case .author(let author):
            return author
        }
    }
    
    var displayString: String {
        switch self {
        case .note:
            return Localized.note.string
        case .author:
            return Localized.profile.string
        }
    }
    
    var tag: [String] {
        switch self {
        case .author(let author):
            if let pubKey = author.hexadecimalPublicKey {
                return ["p", pubKey]
            }
        case .note(let note):
            if let eventID = note.identifier {
                return ["e", eventID]
            }
        }
        
        return []
    }
}
