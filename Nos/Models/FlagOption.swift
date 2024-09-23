import Foundation

/// A model representing a flagging option used in content moderation.
/// - `title`: The title of the flagging option.
/// - `description`: An optional description that provides more detail about the flagging option.
/// - `info`: An optional message that will be displayed when the user has selected a particular flag.
/// - `id`: A unique identifier for the flagging option, based on the `title`.
/// - `category`: The specific category thet the selected flagging option falls in.

struct FlagOption: Identifiable, Equatable {
    let title: String
    let description: String?
    let info: String?
    var id: String { title }
    var category: FlagCategory

    /// `FlagOption` instances representing different categories of content that can be flagged.
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

    static func == (lhs: FlagOption, rhs: FlagOption) -> Bool {
        lhs.id == rhs.id
    }
}

/// Specifies the category associated with a specific flag.
enum FlagCategory {
    case report(ReportCategory)
    case privacy(SendFlagPrivacy)
}

/// Specifies whether a flag should be sent privately to Nos or made public.
enum SendFlagPrivacy {
    case sendToNos
    case publicly
}
