//
//  Report.swift
//  Nos
//
//  Created by Matthew Lorentz on 5/24/23.
//

import Foundation

struct Report {
    var target: ReportTarget
    var reasons: [ReportCategory]
}

enum ReportTarget {
    case event(Event)
    case author(Author)
    
    var author: Author? {
        switch self {
        case .event(let event):
            return event.author
        case .author(let author):
            return author
        }
    }
}

struct ReportCategory: Identifiable {
    var displayName: String 
    var code: String 
    var subCategories: [ReportCategory]?
    
    var id: String { code }
}

let topLevelCategories = [
    ReportCategory(displayName: "Coarse Language", code: "CL"),
    ReportCategory(
        displayName: "Illegal Content", 
        code: "IL", 
        subCategories: [
            ReportCategory(displayName: "Copyright violation", code: "IL-cop"),
            ReportCategory(displayName: "Child sexual abuse", code: "IL-csa"),
            ReportCategory(displayName: "Drug-related crime", code: "IL-drg"),
            ReportCategory(displayName: "Fraud & Scams", code: "IL-frd"),
        ]
    ),
]

