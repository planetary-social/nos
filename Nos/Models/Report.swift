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

//protocol ReportCategory: CaseIterable {
//    var code: String { get }
//    var displayName: String { get }
//    var subCategory: any ReportCategory { get }
//}
//
//enum TopLevelReportCategory: CaseIterable {
//    
//    case coarseLangauage
//    case hate
//    //    case illegal
//    //    case nudity
//    //    case pornography
//    //    case spam
//    //    case violence
//    //    case other
//    
//    var code: String {
//        switch self {
//        case .coarseLangauage:
//            return "CL"
//        case .hate(let subCategory):
//            return subCategory.rawValue
//        }
//    }
//    
//    var displayName: String {
//        switch self {
//        case .coarseLangauage:
//            return "Coarse Language / Profanity"
//        case .hate(let subCategory):
//            return subCategory.rawValue
//        }
//    }
//    
//    var subCategory: any ReportCategory {
//        switch self {
//        case .coarseLangauage:
//            return nil
//        case .hate:
//            return HatefulContent
//        }
//    }
//}
//
//enum HatefulContent: String, CaseIterable {
//    case financial = "HC-fin"
//    case harm = "HC-bhd"
//    case hate = "IH"
//    
//    var displayName: String {
//        switch self {
//        case .financial:
//            return "Fraud & Scams"
//        case .harm:
//            return "Likely to cause harm"
//        case .hate:
//            return "Intolerance & Hate"
//        }
//    }
//}
