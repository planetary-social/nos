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
        displayName: "Likely to cause harm", 
        code: "HC",
        subCategories: [
            ReportCategory(displayName: "Financial Harm", code: "HC-fin"),
            ReportCategory(displayName: "Bodily Harm", code: "HC-bhd"),
        ]
    ),
    ReportCategory(displayName: "Intolerance & Hate", code: "IH"),
    ReportCategory(
        displayName: "Illegal", 
        code: "IL",
        subCategories: [
            ReportCategory(displayName: "Copyright Violation", code: "IL-cop"),
            ReportCategory(displayName: "Child Sexual Abuse", code: "IL-csa"),
            ReportCategory(displayName: "Drug-related crime", code: "IL-drg"),
            ReportCategory(displayName: "Fraud & Scams", code: "IL-frd"),
            ReportCategory(displayName: "Harassment, Stalking, or Doxxing", code: "IL-har"),
            ReportCategory(displayName: "Prostitution", code: "IL-swk"),
            ReportCategory(displayName: "Impersonation", code: "IL-idt"),
            ReportCategory(displayName: "Malware", code: "IL-mal"),
        ]
    ),
    ReportCategory(
        displayName: "Nudity & Sex", 
        code: "NS",
        subCategories: [
            ReportCategory(displayName: "Casual nudity", code: "NS-nud"),
            ReportCategory(displayName: "Erotica", code: "NS-ero"),
            ReportCategory(displayName: "Sex", code: "NS-sex"),
        ]
    ),
    ReportCategory(
        displayName: "Pornography", 
        code: "PN",
        subCategories: [
            ReportCategory(displayName: "Heterosexual Porn", code: "PN-het"),
            ReportCategory(displayName: "Gay male pron", code: "PN-gay"),
            ReportCategory(displayName: "Lesbian porn", code: "PN-les"),
            ReportCategory(displayName: "Bisexual porn", code: "PN-bis"),
            ReportCategory(displayName: "Transsexual porn", code: "PN-trn"),
            ReportCategory(displayName: "Gender-fluid / non-binary porn", code: "PN-fnb"),
        ]
    ),
    ReportCategory(displayName: "Spam", code: "SP"),
    ReportCategory(
        displayName: "Violence", 
        code: "VI",
        subCategories: [
            ReportCategory(displayName: "Violence towards a human being", code: "VI-hum"),
            ReportCategory(displayName: "Violence towards a sentient animal", code: "VI-ani"),
        ]
    ),
    ReportCategory(displayName: "Other", code: "NA"),
]
