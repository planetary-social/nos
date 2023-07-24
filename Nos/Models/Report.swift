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

/// A model for potential reasons why something might be reported.
struct ReportCategory: Identifiable {
    
    /// A human readable description of the reason/category. Should be short enough to fit in an action menu.
    var displayName: String 
    
    /// The machine-readable code corresponding to this category. 
    var code: String 
    
    /// A code matching a NIP-56 category, for backwards compatibility
    var nip56Code: NIP56Code
    
    /// A list of all sub-categories that narrow this one down.
    var subCategories: [ReportCategory]?
    
    var id: String { code }
}

enum NIP56Code: String {
    case nudity, profanity, illegal, spam, impersonation, other
}

/// Vocabulary from [NIP-69](https://github.com/nostr-protocol/nips/pull/457).
let topLevelCategories = [
    ReportCategory(displayName: "Coarse Language", code: "CL", nip56Code: .profanity),
    ReportCategory(
        displayName: "Likely to cause harm", 
        code: "HC",
        nip56Code: .other,
        subCategories: [
            ReportCategory(displayName: "Financial Harm", code: "HC-fin", nip56Code: .other),
            ReportCategory(displayName: "Bodily Harm", code: "HC-bhd", nip56Code: .other),
        ]
    ),
    ReportCategory(displayName: "Intolerance & Hate", code: "IH", nip56Code: .other),
    ReportCategory(
        displayName: "Illegal", 
        code: "IL",
        nip56Code: .illegal,
        subCategories: [
            ReportCategory(displayName: "Copyright Violation", code: "IL-cop", nip56Code: .illegal),
            ReportCategory(displayName: "Child Sexual Abuse", code: "IL-csa", nip56Code: .illegal),
            ReportCategory(displayName: "Drug-related crime", code: "IL-drg", nip56Code: .illegal),
            ReportCategory(displayName: "Fraud & Scams", code: "IL-frd", nip56Code: .illegal),
            ReportCategory(displayName: "Harassment, Stalking, or Doxxing", code: "IL-har", nip56Code: .illegal),
            ReportCategory(displayName: "Prostitution", code: "IL-swk", nip56Code: .illegal),
            ReportCategory(displayName: "Impersonation", code: "IL-idt", nip56Code: .illegal),
            ReportCategory(displayName: "Malware", code: "IL-mal", nip56Code: .illegal),
        ]
    ),
    ReportCategory(
        displayName: "Nudity & Sex", 
        code: "NS",
        nip56Code: .nudity,
        subCategories: [
            ReportCategory(displayName: "Casual nudity", code: "NS-nud", nip56Code: .nudity),
            ReportCategory(displayName: "Erotica", code: "NS-ero", nip56Code: .nudity),
            ReportCategory(displayName: "Sex", code: "NS-sex", nip56Code: .nudity),
        ]
    ),
    ReportCategory(
        displayName: "Pornography", 
        code: "PN",
        nip56Code: .nudity,
        subCategories: [
            ReportCategory(displayName: "Heterosexual Porn", code: "PN-het", nip56Code: .nudity),
            ReportCategory(displayName: "Gay male pron", code: "PN-gay", nip56Code: .nudity),
            ReportCategory(displayName: "Lesbian porn", code: "PN-les", nip56Code: .nudity),
            ReportCategory(displayName: "Bisexual porn", code: "PN-bis", nip56Code: .nudity),
            ReportCategory(displayName: "Transsexual porn", code: "PN-trn", nip56Code: .nudity),
            ReportCategory(displayName: "Gender-fluid / non-binary porn", code: "PN-fnb", nip56Code: .nudity),
        ]
    ),
    ReportCategory(displayName: "Spam", code: "SP", nip56Code: .spam),
    ReportCategory(
        displayName: "Violence", 
        code: "VI",
        nip56Code: .other,
        subCategories: [
            ReportCategory(displayName: "Violence towards a human being", code: "VI-hum", nip56Code: .other),
            ReportCategory(displayName: "Violence towards a sentient animal", code: "VI-ani", nip56Code: .other),
        ]
    ),
    ReportCategory(displayName: "Other", code: "NA", nip56Code: .other),
]
