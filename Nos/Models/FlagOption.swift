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

    /// `FlagOption` instances representing different categories of content and accounts that can be flagged.
    static let flagContentCategories: [FlagOption] = [
        FlagOption(
            title: String(localized: .localizable.flagContentSpamTitle),
            description: nil,
            info: nil,
            category: .report(ReportCategoryType.spam)
        ),
        FlagOption(
            title: String(localized: .localizable.flagContentHarassmentTitle),
            description: String(localized: .localizable.flagContentHarassmentDescription),
            info: nil,
            category: .report(ReportCategoryType.harassment)
        ),
        FlagOption(
            title: "NSFW",
            description: String(localized: .localizable.flagContentNudityDescription),
            info: nil,
            category: .report(ReportCategoryType.nsfw)
        ),
        FlagOption(
            title: String(localized: .localizable.flagContentIllegalTitle),
            description: String(localized: .localizable.flagContentIllegalDescription),
            info: nil,
            category: .report(ReportCategoryType.illegal)
        ),
        FlagOption(
            title: String(localized: .localizable.flagContentOtherTitle),
            description: String(localized: .localizable.flagContentOtherDescription),
            info: nil,
            category: .report(ReportCategoryType.other)
        )
    ]

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

/// Specifies whether a flagged account should be muted or not..
enum FlagAccountVisibility {
    case mute
    case unmute
}
