//
//  ReportCategory.swift
//  Nos
//
//  Created by Matthew Lorentz on 7/27/23.
//

import Foundation

/// A model for potential reasons why something might be reported.
struct ReportCategory: Identifiable, Equatable {
    
    /// A localized human readable description of the reason/category. Should be short enough to fit in an action menu.
    var displayName: String {
        string
    }    
    
    /// An english translation of the category name that should not be shown to the user.
    var debugName: String 
    
    /// The machine-readable code corresponding to this category. 
    var code: String 
    
    /// A code matching a NIP-56 category, for backwards compatibility
    var nip56Code: NIP56Code
    
    /// A list of all sub-categories that narrow this one down.
    var subCategories: [ReportCategory]?
    
    var id: String { code }
}

extension ReportCategory: Localizable {
    var template: String {
        debugName
    }
    
    static func flatten(category: ReportCategory) -> [ReportCategory] {
        var flatList = [category]
        if let subCategories = category.subCategories {
            flatList.append(contentsOf: subCategories.flatMap { flatten(category: $0) })
        }
        return flatList
    }
    
    static func exportForStringsFile() -> String {
        topLevelCategories
            .flatMap { flatten(category: $0) }
            .map { "\"\($0.key)\" = \"\($0.debugName)\";" }
            .joined(separator: "\n")
    }
    
    var key: String {
        "Moderation.\(code)"
    }
}

enum NIP56Code: String {
    case nudity, profanity, illegal, spam, impersonation, other
}

/// Vocabulary from [NIP-69](https://github.com/nostr-protocol/nips/pull/457).
let topLevelCategories = [
    ReportCategory(debugName: "Coarse Language", code: "CL", nip56Code: .profanity),
    ReportCategory(
        debugName: "Likely to cause harm", 
        code: "HC",
        nip56Code: .other,
        subCategories: [
            ReportCategory(debugName: "Financial Harm", code: "HC-fin", nip56Code: .other),
            ReportCategory(debugName: "Bodily Harm", code: "HC-bhd", nip56Code: .other),
        ]
    ),
    ReportCategory(debugName: "Intolerance & Hate", code: "IH", nip56Code: .other),
    ReportCategory(
        debugName: "Illegal", 
        code: "IL",
        nip56Code: .illegal,
        subCategories: [
            ReportCategory(debugName: "Copyright Violation", code: "IL-cop", nip56Code: .illegal),
            ReportCategory(debugName: "Child Sexual Abuse", code: "IL-csa", nip56Code: .illegal),
            ReportCategory(debugName: "Drug-related crime", code: "IL-drg", nip56Code: .illegal),
            ReportCategory(debugName: "Fraud & Scams", code: "IL-frd", nip56Code: .illegal),
            ReportCategory(debugName: "Harassment, Stalking, or Doxxing", code: "IL-har", nip56Code: .illegal),
            ReportCategory(debugName: "Prostitution", code: "IL-swk", nip56Code: .illegal),
            ReportCategory(debugName: "Impersonation", code: "IL-idt", nip56Code: .illegal),
            ReportCategory(debugName: "Malware", code: "IL-mal", nip56Code: .illegal),
        ]
    ),
    ReportCategory(
        debugName: "Nudity & Sex", 
        code: "NS",
        nip56Code: .nudity,
        subCategories: [
            ReportCategory(debugName: "Casual nudity", code: "NS-nud", nip56Code: .nudity),
            ReportCategory(debugName: "Erotica", code: "NS-ero", nip56Code: .nudity),
            ReportCategory(debugName: "Sex", code: "NS-sex", nip56Code: .nudity),
        ]
    ),
    ReportCategory(
        debugName: "Pornography", 
        code: "PN",
        nip56Code: .nudity,
        subCategories: [
            ReportCategory(debugName: "Heterosexual Porn", code: "PN-het", nip56Code: .nudity),
            ReportCategory(debugName: "Gay male pron", code: "PN-gay", nip56Code: .nudity),
            ReportCategory(debugName: "Lesbian porn", code: "PN-les", nip56Code: .nudity),
            ReportCategory(debugName: "Bisexual porn", code: "PN-bis", nip56Code: .nudity),
            ReportCategory(debugName: "Transsexual porn", code: "PN-trn", nip56Code: .nudity),
            ReportCategory(debugName: "Gender-fluid / non-binary porn", code: "PN-fnb", nip56Code: .nudity),
        ]
    ),
    ReportCategory(debugName: "Spam", code: "SP", nip56Code: .spam),
    ReportCategory(
        debugName: "Violence", 
        code: "VI",
        nip56Code: .other,
        subCategories: [
            ReportCategory(debugName: "Violence towards a human being", code: "VI-hum", nip56Code: .other),
            ReportCategory(debugName: "Violence towards a sentient animal", code: "VI-ani", nip56Code: .other),
        ]
    ),
    ReportCategory(debugName: "Other", code: "NA", nip56Code: .other),
]
