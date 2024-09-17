import Foundation

/// A model representing a flagging option used in content moderation.
/// - `title`: The title of the flagging option.
/// - `description`: An optional description that provides more detail about the flagging option.
/// - `id`: A unique identifier for the flagging option, based on the `title`.

struct FlagOption: Identifiable {
    let title: String
    let description: String?
    var id: String { title }

    /// `FlagOption` instances representing different categories of content that can be flagged.
    static let flagContentCategories: [FlagOption] = [
        FlagOption(
            title: String(localized: .localizable.spam),
            description: nil
        ),
        FlagOption(
            title: String(localized: .localizable.harassmentFlagContentTitle),
            description: String(localized: .localizable.harassmentFlagContentDescription)
        ),
        FlagOption(
            title: "NSFW",
            description: String(localized: .localizable.nudityFlagContentDescription)
        ),
        FlagOption(
            title: String(localized: .localizable.illegalFlagContentTitle),
            description: String(localized: .localizable.illegalFlagContentDescription)
        ),
        FlagOption(
            title: String(localized: .localizable.others),
            description: String(localized: .localizable.otherFlagContentDescription)
        )
    ]
}
