import Foundation

/// A model for potential reasons why something might be reported.
/// Vocabulary from [NIP-56] and [NIP-69](https://github.com/nostr-protocol/nips/pull/457).
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
        name: .moderation.coarseLanguage,
        code: "CL",
        nip56Code: .profanity
    )
    
    static let likelyToCauseHarm = ReportCategory(
        name: .moderation.likelyToCauseHarm,
        code: "HC",
        nip56Code: .other
    )

    static let harassment = ReportCategory(
        name: .moderation.harassment,
        code: "IL-har",
        nip56Code: .profanity
    )

    static let intoleranceAndHate = ReportCategory(
        name: .moderation.intoleranceAndHate,
        code: "IH",
        nip56Code: .other
    )
    
    static let illegal = ReportCategory(
        name: .moderation.illegal,
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
        name: .moderation.nsfw,
        code: "NW",
        nip56Code: .nudity
    )
    
    static let impersonation = ReportCategory(
        name: .moderation.impersonation,
        code: "IM",
        nip56Code: .impersonation
    )

    static let nudity = ReportCategory(
        name: .moderation.nudityAndSex,
        code: "NS",
        nip56Code: .nudity,
        subCategories: [
            ReportSubCategoryType.casualNudity,
            ReportSubCategoryType.erotica,
            ReportSubCategoryType.sex,
        ]
    )
    
    static let pornography = ReportCategory(
        name: .moderation.pornography,
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
    
    static let spam = ReportCategory(name: .moderation.spam, code: "SP", nip56Code: .spam)

    static let violence = ReportCategory(
        name: .moderation.violence,
        code: "VI",
        nip56Code: .other,
        subCategories: [
            ReportSubCategoryType.violenceTowardsAHumanBeing,
            ReportSubCategoryType.violenceTowardsASentientAnimal,
        ]
    )

    static let other = ReportCategory(name: .moderation.other, code: "NA", nip56Code: .other)
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
        name: .moderation.copyrightViolation,
        code: "IL-cop",
        nip56Code: .illegal
    )
    
    static let childSexualAbuse = ReportCategory(
        name: .moderation.childSexualAbuse,
        code: "IL-csa",
        nip56Code: .illegal
    )
    static let drugRelatedCrime = ReportCategory(
        name: .moderation.drugRelatedCrime,
        code: "IL-drg",
        nip56Code: .illegal
    )
    
    static let fraudAndScams = ReportCategory(
        name: .moderation.fraudAndScams,
        code: "IL-frd",
        nip56Code: .illegal
    )
    
    static let harassmentStalkingOrDoxxing = ReportCategory(
        name: .moderation.harassmentStalkingOrDoxxing,
        code: "IL-har",
        nip56Code: .illegal
    )
    
    static let prostitution = ReportCategory(
        name: .moderation.prostitution,
        code: "IL-swk",
        nip56Code: .illegal
    )
    
    static let impersonation = ReportCategory(
        name: .moderation.impersonation,
        code: "IL-idt",
        nip56Code: .illegal
    )
    
    static let malware = ReportCategory(
        name: .moderation.malware,
        code: "IL-mal",
        nip56Code: .illegal
    )
    
    static let casualNudity = ReportCategory(
        name: .moderation.casualNudity,
        code: "NS-nud",
        nip56Code: .nudity
    )
    
    static let erotica = ReportCategory(
        name: .moderation.erotica,
        code: "NS-ero",
        nip56Code: .nudity
    )
    
    // swiftlint:disable:next identifier_name
    static let sex = ReportCategory(
        name: .moderation.sex,
        code: "NS-sex",
        nip56Code: .nudity
    )
    
    static let heterosexualPorn = ReportCategory(
        name: .moderation.heterosexualPorn,
        code: "PN-het",
        nip56Code: .nudity
    )
    
    static let gayMalePorn = ReportCategory(
        name: .moderation.gayMalePorn,
        code: "PN-gay",
        nip56Code: .nudity
    )
    
    static let lesbianPorn = ReportCategory(
        name: .moderation.lesbianPorn,
        code: "PN-les",
        nip56Code: .nudity
    )
    
    static let bisexualPorn = ReportCategory(
        name: .moderation.bisexualPorn,
        code: "PN-bis",
        nip56Code: .nudity
    )
    
    static let transsexualPorn = ReportCategory(
        name: .moderation.transsexualPorn,
        code: "PN-trn",
        nip56Code: .nudity
    )
    
    static let genderFluidNonBinaryPorn = ReportCategory(
        name: .moderation.genderFluidNonBinaryPorn,
        code: "PN-fnb",
        nip56Code: .nudity
    )
    
    static let violenceTowardsAHumanBeing = ReportCategory(
        name: .moderation.violenceTowardsAHumanBeing,
        code: "VI-hum",
        nip56Code: .other
    )
    
    static let violenceTowardsASentientAnimal = ReportCategory(
        name: .moderation.violenceTowardsASentientAnimal,
        code: "VI-ani",
        nip56Code: .other
    )
}
