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
    var category: Any

    /// `FlagOption` instances representing different categories of content that can be flagged.
    static let flagContentCategories: [FlagOption] = [
        FlagOption(
            title: String(localized: .localizable.flagContentSpamTitle),
            description: nil, 
            info: nil,
            category: ReportCategoryType.spam
        ),
        FlagOption(
            title: String(localized: .localizable.flagContentHarassmentTitle),
            description: String(localized: .localizable.flagContentHarassmentDescription),
            info: nil,
            category: ReportCategoryType.harassment
        ),
        FlagOption(
            title: "NSFW",
            description: String(localized: .localizable.flagContentNudityDescription),
            info: nil,
            category: ReportCategoryType.nsfw
        ),
        FlagOption(
            title: String(localized: .localizable.flagContentIllegalTitle),
            description: String(localized: .localizable.flagContentIllegalDescription),
            info: nil,
            category: ReportCategoryType.illegal
        ),
        FlagOption(
            title: String(localized: .localizable.flagContentOtherTitle),
            description: String(localized: .localizable.flagContentOtherDescription),
            info: nil,
            category: ReportCategoryType.other
        )
    ]

    /// `FlagOption` instances representing different categories of how a content can can be flagged.
    static let flagContentSendCategories: [FlagOption] = [
        FlagOption(
            title: String(localized: .localizable.flagContentSendToNosTitle),
            description: String(localized: .localizable.flagContentSendToNosDescription),
            info: String(localized: .localizable.flagContentSendToNosInfo),
            category: SendFlagPrivacy.sendToNos
        ),
        FlagOption(
            title: String(localized: .localizable.flagContentFlagPubiclyTitle),
            description: String(localized: .localizable.flagContentFlagPubiclyDescription),
            info: nil,
            category: SendFlagPrivacy.publicly
        )
    ]

    static func == (lhs: FlagOption, rhs: FlagOption) -> Bool {
        lhs.id == rhs.id
    }
}

/// Specifies whether a flag should be sent privately to Nos or made public.
enum SendFlagPrivacy {
    case sendToNos
    case publicly
}
