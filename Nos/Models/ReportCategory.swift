import Foundation

/// A model for potential reasons why something might be reported.
/// Vocabulary from [NIP-56] and [NIP-69](https://github.com/nostr-protocol/nips/pull/457).
struct ReportCategory: Identifiable, Equatable {
    /// A localized human readable description of the reason/category. Should be short enough to fit in an action menu.
    let displayName: String
    
    /// The machine-readable code corresponding to this category.
    let code: String
    
    /// A code matching a NIP-56 category, for backwards compatibility
    let nip56Code: NIP56Code
    
    /// A list of all sub-categories that narrow this one down.
    var subCategories: [ReportCategory]?
    
    var id: String { code }
    
    static func findCategory(from code: String) -> ReportCategory? {
        var searchForCategoryByCode: ((String, [ReportCategory]) -> ReportCategory?)?
        searchForCategoryByCode = { (code: String, categories: [ReportCategory]) -> ReportCategory? in
            for category in categories {
                if category.code == code {
                    return category
                } else if let subCategories = category.subCategories {
                    if let subCategory = searchForCategoryByCode?(code, subCategories) {
                        return subCategory
                    }
                }
            }
            
            return nil
        }
        
        return searchForCategoryByCode?(code, ReportCategory.allCategories)
    }
}

enum NIP56Code: String {
    case nudity, malware, profanity, illegal, spam, impersonation, other
}

extension ReportCategory {
    static let coarseLanguage = ReportCategory(
        displayName: String(localized: "coarseLanguage", table: "Moderation"),
        code: "CL",
        nip56Code: .profanity
    )
    
    static let likelyToCauseHarm = ReportCategory(
        displayName: String(localized: "likelyToCauseHarm", table: "Moderation"),
        code: "HC",
        nip56Code: .other
    )

    static let harassment = ReportCategory(
        displayName: String(localized: "harassment", table: "Moderation"),
        code: "IL-har",
        nip56Code: .profanity
    )

    static let intoleranceAndHate = ReportCategory(
        displayName: String(localized: "intoleranceAndHate", table: "Moderation"),
        code: "IH",
        nip56Code: .other
    )
    
    static let illegal = ReportCategory(
        displayName: String(localized: "illegal", table: "Moderation"),
        code: "IL",
        nip56Code: .illegal,
        subCategories: [
            ReportSubCategoryType.copyrightViolation,
            ReportSubCategoryType.childSexualAbuse,
            ReportSubCategoryType.drugRelatedCrime,
            ReportSubCategoryType.fraudAndScams,
            ReportSubCategoryType.harassmentStalkingOrDoxxing,
            ReportSubCategoryType.prostitution,
            ReportSubCategoryType.impersonation,
            ReportSubCategoryType.malware,
        ]
    )

    static let nsfw = ReportCategory(
        displayName: String(localized: "nsfw", table: "Moderation"),
        code: "NW",
        nip56Code: .nudity
    )
    
    static let impersonation = ReportCategory(
        displayName: String(localized: "impersonation", table: "Moderation"),
        code: "IM",
        nip56Code: .impersonation
    )

    static let nudity = ReportCategory(
        displayName: String(localized: "nudityAndSex", table: "Moderation"),
        code: "NS",
        nip56Code: .nudity,
        subCategories: [
            ReportSubCategoryType.casualNudity,
            ReportSubCategoryType.erotica,
            ReportSubCategoryType.sex,
        ]
    )
    
    static let pornography = ReportCategory(
        displayName: String(localized: "pornography", table: "Moderation"),
        code: "PN",
        nip56Code: .nudity,
        subCategories: [
            ReportSubCategoryType.heterosexualPorn,
            ReportSubCategoryType.gayMalePorn,
            ReportSubCategoryType.lesbianPorn,
            ReportSubCategoryType.bisexualPorn,
            ReportSubCategoryType.transsexualPorn,
            ReportSubCategoryType.genderFluidNonBinaryPorn,
        ]
    )
    
    static let spam = ReportCategory(
        displayName: String(localized: "spam", table: "Moderation"),
        code: "SP",
        nip56Code: .spam
    )

    static let violence = ReportCategory(
        displayName: String(localized: "violence", table: "Moderation"),
        code: "VI",
        nip56Code: .other,
        subCategories: [
            ReportSubCategoryType.violenceTowardsAHumanBeing,
            ReportSubCategoryType.violenceTowardsASentientAnimal,
        ]
    )

    static let other = ReportCategory(
        displayName: String(localized: "other", table: "Moderation"),
        code: "NA",
        nip56Code: .other
    )
}

extension ReportCategory {
    static let allCategories: [ReportCategory] = [
        .coarseLanguage,
        .likelyToCauseHarm,
        .harassment,
        .intoleranceAndHate,
        .impersonation,
        .illegal,
        .nsfw,
        .nudity,
        .pornography,
        .spam,
        .violence,
        .other,
    ]

    static let authorCategories: [ReportCategory] = [
        .spam,
        .harassment,
        .nudity,
        .illegal,
        .impersonation,
        .other,
    ]

    static let noteCategories: [ReportCategory] = [
        .spam,
        .nudity,
        .coarseLanguage,
        .illegal,
        .other,
    ]
}

enum ReportSubCategoryType {
    static let copyrightViolation = ReportCategory(
        displayName: String(localized: "copyrightViolation", table: "Moderation"),
        code: "IL-cop",
        nip56Code: .illegal
    )
    
    static let childSexualAbuse = ReportCategory(
        displayName: String(localized: "childSexualAbuse", table: "Moderation"),
        code: "IL-csa",
        nip56Code: .illegal
    )
    static let drugRelatedCrime = ReportCategory(
        displayName: String(localized: "drugRelatedCrime", table: "Moderation"),
        code: "IL-drg",
        nip56Code: .illegal
    )
    
    static let fraudAndScams = ReportCategory(
        displayName: String(localized: "fraudAndScams", table: "Moderation"),
        code: "IL-frd",
        nip56Code: .illegal
    )
    
    static let harassmentStalkingOrDoxxing = ReportCategory(
        displayName: String(localized: "harassmentStalkingOrDoxxing", table: "Moderation"),
        code: "IL-har",
        nip56Code: .illegal
    )
    
    static let prostitution = ReportCategory(
        displayName: String(localized: "prostitution", table: "Moderation"),
        code: "IL-swk",
        nip56Code: .illegal
    )
    
    static let impersonation = ReportCategory(
        displayName: String(localized: "impersonation", table: "Moderation"),
        code: "IL-idt",
        nip56Code: .illegal
    )
    
    static let malware = ReportCategory(
        displayName: String(localized: "malware", table: "Moderation"),
        code: "IL-mal",
        nip56Code: .illegal
    )
    
    static let casualNudity = ReportCategory(
        displayName: String(localized: "casualNudity", table: "Moderation"),
        code: "NS-nud",
        nip56Code: .nudity
    )
    
    static let erotica = ReportCategory(
        displayName: String(localized: "erotica", table: "Moderation"),
        code: "NS-ero",
        nip56Code: .nudity
    )
    
    // swiftlint:disable:next identifier_name
    static let sex = ReportCategory(
        displayName: String(localized: "sex", table: "Moderation"),
        code: "NS-sex",
        nip56Code: .nudity
    )
    
    static let heterosexualPorn = ReportCategory(
        displayName: String(localized: "heterosexualPorn", table: "Moderation"),
        code: "PN-het",
        nip56Code: .nudity
    )
    
    static let gayMalePorn = ReportCategory(
        displayName: String(localized: "gayMalePorn", table: "Moderation"),
        code: "PN-gay",
        nip56Code: .nudity
    )
    
    static let lesbianPorn = ReportCategory(
        displayName: String(localized: "lesbianPorn", table: "Moderation"),
        code: "PN-les",
        nip56Code: .nudity
    )
    
    static let bisexualPorn = ReportCategory(
        displayName: String(localized: "bisexualPorn", table: "Moderation"),
        code: "PN-bis",
        nip56Code: .nudity
    )
    
    static let transsexualPorn = ReportCategory(
        displayName: String(localized: "transsexualPorn", table: "Moderation"),
        code: "PN-trn",
        nip56Code: .nudity
    )
    
    static let genderFluidNonBinaryPorn = ReportCategory(
        displayName: String(localized: "genderFluidNonBinaryPorn", table: "Moderation"),
        code: "PN-fnb",
        nip56Code: .nudity
    )
    
    static let violenceTowardsAHumanBeing = ReportCategory(
        displayName: String(localized: "violenceTowardsAHumanBeing", table: "Moderation"),
        code: "VI-hum",
        nip56Code: .other
    )
    
    static let violenceTowardsASentientAnimal = ReportCategory(
        displayName: String(localized: "violenceTowardsASentientAnimal", table: "Moderation"),
        code: "VI-ani",
        nip56Code: .other
    )
}
