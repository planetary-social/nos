import Foundation

/// A model representing a flagging option used in content moderation.
/// - `title`: The title of the flagging option.
/// - `description`: An optional description that provides more detail about the flagging option.
/// - `info`: An optional message that will be displayed when the user has selected a particular flag.
/// - `id`: A unique identifier for the flagging option, based on the `title`.
struct FlagOption: Identifiable, Equatable {
    let title: String
    let description: String?
    let info: String?
    var id: String { title }

    /// `FlagOption` instances representing different categories of content that can be flagged.
    static let flagContentCategories: [FlagOption] = [
        FlagOption(
            title: String(localized: .localizable.flagContentSpamTitle),
            description: nil,
            info: nil
        ),
        FlagOption(
            title: String(localized: .localizable.flagContentHarassmentTitle),
            description: String(localized: .localizable.flagContentHarassmentDescription),
            info: nil
        ),
        FlagOption(
            title: "NSFW",
            description: String(localized: .localizable.flagContentNudityDescription),
            info: nil
        ),
        FlagOption(
            title: String(localized: .localizable.flagContentIllegalTitle),
            description: String(localized: .localizable.flagContentIllegalDescription),
            info: nil
        ),
        FlagOption(
            title: String(localized: .localizable.flagContentOtherTitle),
            description: String(localized: .localizable.flagContentOtherDescription),
            info: nil
        )
    ]

    /// `FlagOption` instances representing different categories of how a content can can be flagged.
    static let flagContentSendCategories: [FlagOption] = [
        FlagOption(
            title: String(localized: .localizable.flagContentSendToNosTitle),
            description: String(localized: .localizable.flagContentSendToNosDescription),
            info: String(localized: .localizable.flagContentSendToNosInfo)
        ),
        FlagOption(
            title: String(localized: .localizable.flagContentFlagPubiclyTitle),
            description: String(localized: .localizable.flagContentFlagPubiclyDescription),
            info: nil
        )
    ]
}
