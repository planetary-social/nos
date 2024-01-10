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
        String(localized: name)
    }    

    var name: LocalizedStringResource

    /// The machine-readable code corresponding to this category. 
    var code: String 
    
    /// A code matching a NIP-56 category, for backwards compatibility
    var nip56Code: NIP56Code
    
    /// A list of all sub-categories that narrow this one down.
    var subCategories: [ReportCategory]?
    
    var id: String { code }
 
    static func findCategory(from code: String) -> ReportCategory? {
        var searchForCategoryByCode: ((String, [ReportCategory]) -> ReportCategory?)?
        searchForCategoryByCode = { (code: String, categories: [ReportCategory]) -> ReportCategory? in
            for category in categories {
                if category.code == code {
                    return category
                } else if let subCategories = category.subCategories,
                    let subCategory = searchForCategoryByCode?(code, subCategories) {
                    return subCategory
                }
            }
            
            return nil
        }
        
        return searchForCategoryByCode?(code, topLevelCategories)
    }  
}

enum NIP56Code: String {
    case nudity, profanity, illegal, spam, impersonation, other
}

/// Vocabulary from [NIP-69](https://github.com/nostr-protocol/nips/pull/457).
let topLevelCategories = [
    ReportCategory(name: .moderation.coarseLanguage, code: "CL", nip56Code: .profanity),
    ReportCategory(
        name: .moderation.likelyToCauseHarm,
        code: "HC",
        nip56Code: .other,
        subCategories: [
            ReportCategory(name: .moderation.financialHarm, code: "HC-fin", nip56Code: .other),
            ReportCategory(name: .moderation.bodilyHarm, code: "HC-bhd", nip56Code: .other),
        ]
    ),
    ReportCategory(name: .moderation.intoleranceAndHate, code: "IH", nip56Code: .other),
    ReportCategory(
        name: .moderation.illegal,
        code: "IL",
        nip56Code: .illegal,
        subCategories: [
            ReportCategory(name: .moderation.copyrightViolation, code: "IL-cop", nip56Code: .illegal),
            ReportCategory(name: .moderation.childSexualAbuse, code: "IL-csa", nip56Code: .illegal),
            ReportCategory(name: .moderation.drugRelatedCrime, code: "IL-drg", nip56Code: .illegal),
            ReportCategory(name: .moderation.fraudAndScams, code: "IL-frd", nip56Code: .illegal),
            ReportCategory(name: .moderation.harassmentStalkingOrDoxxing, code: "IL-har", nip56Code: .illegal),
            ReportCategory(name: .moderation.prostitution, code: "IL-swk", nip56Code: .illegal),
            ReportCategory(name: .moderation.impersonation, code: "IL-idt", nip56Code: .illegal),
            ReportCategory(name: .moderation.malware, code: "IL-mal", nip56Code: .illegal),
        ]
    ),
    ReportCategory(
        name: .moderation.nudityAndSex,
        code: "NS",
        nip56Code: .nudity,
        subCategories: [
            ReportCategory(name: .moderation.casualNudity, code: "NS-nud", nip56Code: .nudity),
            ReportCategory(name: .moderation.erotica, code: "NS-ero", nip56Code: .nudity),
            ReportCategory(name: .moderation.sex, code: "NS-sex", nip56Code: .nudity),
        ]
    ),
    ReportCategory(
        name: .moderation.pornography,
        code: "PN",
        nip56Code: .nudity,
        subCategories: [
            ReportCategory(name: .moderation.heterosexualPorn, code: "PN-het", nip56Code: .nudity),
            ReportCategory(name: .moderation.gayMalePorn, code: "PN-gay", nip56Code: .nudity),
            ReportCategory(name: .moderation.lesbianPorn, code: "PN-les", nip56Code: .nudity),
            ReportCategory(name: .moderation.bisexualPorn, code: "PN-bis", nip56Code: .nudity),
            ReportCategory(name: .moderation.transsexualPorn, code: "PN-trn", nip56Code: .nudity),
            ReportCategory(name: .moderation.genderFluidNonBinaryPorn, code: "PN-fnb", nip56Code: .nudity),
        ]
    ),
    ReportCategory(name: .moderation.spam, code: "SP", nip56Code: .spam),
    ReportCategory(
        name: .moderation.violence,
        code: "VI",
        nip56Code: .other,
        subCategories: [
            ReportCategory(name: .moderation.violenceTowardsAHumanBeing, code: "VI-hum", nip56Code: .other),
            ReportCategory(name: .moderation.violenceTowardsASentientAnimal, code: "VI-ani", nip56Code: .other),
        ]
    ),
    ReportCategory(name: .moderation.other, code: "NA", nip56Code: .other),
]
