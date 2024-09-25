import Foundation

/// A model representing a flagging option used in content moderation.
struct FlagOption: Identifiable, Equatable {
    /// The title of the flagging option.
    let title: String

    /// An optional description that provides more detail about the flagging option.
    let description: String?

    /// An optional message that will be displayed when the user has selected a particular flag.
    let info: String?

    /// A unique identifier for the flagging option, based on the `title`.
    var id: String { title }

    /// The specific category thet the selected flagging option falls in.
    var category: FlagCategory

    /// Creates a list of `FlagOption` categories based on the provided flag target.
    /// - Parameter flagTarget: The target of the report.
    /// - Returns: An array of `FlagOption` categories,  modified based on the `flagTarget`.
    static func createFlagCategories(for flagTarget: ReportTarget) -> [FlagOption] {
        var categories = [spamCategory, harassmentCategory, nsfwCategory, illegalCategory, otherCategory]

        if case .author = flagTarget {
            let insertionIndex = max(categories.count - 1, 0)
            categories.insert(impersonationCategory, at: insertionIndex)
        }

        return categories
    }

    /// `FlagOption` instances representing different categories of how a content can can be flagged.
    static let flagContentSendCategories: [FlagOption] = [
        FlagOption(
            title: String(localized: .localizable.flagContentSendToNosTitle),
            description: String(localized: .localizable.flagContentSendToNosDescription),
            info: String(localized: .localizable.flagContentSendToNosInfo),
            category: .privacy(.sendToNos)
        ),
        FlagOption(
            title: String(localized: .localizable.flagContentFlagPubiclyTitle),
            description: String(localized: .localizable.flagContentFlagPubiclyDescription),
            info: nil,
            category: .privacy(.publicly)
        )
    ]

    /// `FlagOption` instances representing different categories of how an account can be flagged.
    static let flagAccountSendCategories: [FlagOption] = [
        FlagOption(
            title: String(localized: .localizable.flagContentSendToNosTitle),
            description: String(localized: .localizable.flagContentSendToNosDescription),
            info: String(localized: .localizable.flagAccountSendToNosInfo),
            category: .privacy(.sendToNos)
        ),
        FlagOption(
            title: String(localized: .localizable.flagContentFlagPubiclyTitle),
            description: String(localized: .localizable.flagContentFlagPubiclyDescription),
            info: nil,
            category: .privacy(.publicly)
        )
    ]

    /// `FlagOption` instances representing different categories of the visibility of a flagged account.
    static let flagAccountVisibilityCategories: [FlagOption] = [
        FlagOption(
            title: String(localized: .localizable.flagAccountMuteTitle),
            description: String(localized: .localizable.flagAccountMuteDescription),
            info: nil,
            category: .visibility(.mute)
        ),
        FlagOption(
            title: String(localized: .localizable.flagAccountDontMuteTitle),
            description: String(localized: .localizable.flagAccountDontMuteDescription),
            info: nil,
            category: .visibility(.unmute)
        )
    ]

    static func == (lhs: FlagOption, rhs: FlagOption) -> Bool {
        lhs.id == rhs.id
    }
}

extension FlagOption {
    static let spamCategory = FlagOption(
        title: String(localized: .localizable.flagContentSpamTitle),
        description: nil,
        info: nil,
        category: .report(ReportCategoryType.spam)
    )
    
    static let harassmentCategory = FlagOption(
        title: String(localized: .localizable.flagContentHarassmentTitle),
        description: String(localized: .localizable.flagContentHarassmentDescription),
        info: nil,
        category: .report(ReportCategoryType.harassment)
    )

    static let nsfwCategory = FlagOption(
        title: "NSFW",
        description: String(localized: .localizable.flagContentNudityDescription),
        info: nil,
        category: .report(ReportCategoryType.nsfw)
    )

    static let illegalCategory = FlagOption(
        title: String(localized: .localizable.flagContentIllegalTitle),
        description: String(localized: .localizable.flagContentIllegalDescription),
        info: nil,
        category: .report(ReportCategoryType.illegal)
    )

    static let impersonationCategory = FlagOption(
        title: String(localized: .localizable.flagAccountImpersonationTitle),
        description: String(localized: .localizable.flagAccountImpersonationDescription),
        info: nil,
        category: .report(ReportCategoryType.other)
    )

    static let otherCategory = FlagOption(
        title: String(localized: .localizable.flagContentOtherTitle),
        description: String(localized: .localizable.flagContentOtherDescription),
        info: nil,
        category: .report(ReportCategoryType.other)
    )
}

/// Specifies the category associated with a specific flag.
enum FlagCategory {
    case report(ReportCategory)
    case privacy(SendFlagPrivacy)
    case visibility(FlagAccountVisibility)
}

/// Specifies whether a flag should be sent privately to Nos or made public.
enum SendFlagPrivacy {
    case sendToNos
    case publicly
}

/// Specifies whether a flagged account should be muted or not.
enum FlagAccountVisibility {
    case mute
    case unmute
}
