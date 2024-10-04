import Foundation

/// A model representing a flagging option used in content moderation.
struct FlagOption: Identifiable, Equatable {
    /// The title of the flagging option.
    let title: String

    /// An optional description that provides more detail about the flagging option.
    let description: String?

    /// An optional closure that returns a message to display when the user selects a particular flag.
    /// The closure takes the title of the previously selected flag as an optional `String`
    /// and inserts it into a localizable string to provide additional context or details for the current flag.
    /// This message is shown in the info box based on the current selection.
    /// - Parameter String?: The title of the previously selected flag, if available.
    /// - Returns: A message related to the current flag based on the previous selection, 
    /// or `nil` if no message is provided.
    let info: ((String?) -> String?)?

    /// A unique identifier for the flagging option, based on the `title`.
    var id: String { title }

    /// The specific category thet the selected flagging option falls in.
    let category: FlagCategory

    /// Creates a list of `FlagOption` categories based on the provided flag target.
    /// - Parameter flagTarget: The target of the report.
    /// - Returns: An array of `FlagOption` categories,  modified based on the `flagTarget`.
    static func createFlagCategories(for flagTarget: ReportTarget) -> [FlagOption] {
        if case .author = flagTarget {
            return [spam, harassment, nsfw, illegal, other]
        } else {
            return [spam, harassment, nsfw, illegal, impersonation, other]
        }
    }

    /// `FlagOption` instances representing different categories of how a content can can be flagged.
    static let flagContentSendOptions: [FlagOption] = [
        FlagOption(
            title: String(localized: .localizable.flagSendToNosTitle),
            description: String(localized: .localizable.flagSendToNosDescription),
            info: { selectedTitle in
                guard let selectedTitle = selectedTitle else { return nil }
                return String(localized: .localizable.flagUserSendToNosInfo(selectedTitle))
            },
            category: .privacy(.sendToNos)
        ),
        FlagOption(
            title: String(localized: .localizable.flagPubliclyTitle),
            description: String(localized: .localizable.flagPubliclyDescription),
            info: nil,
            category: .privacy(.publicly)
        )
    ]

    /// `FlagOption` instances representing different categories of how a user can be flagged.
    static let flagUserSendOptions: [FlagOption] = [
        FlagOption(
            title: String(localized: .localizable.flagSendToNosTitle),
            description: String(localized: .localizable.flagSendToNosDescription),
            info: { selectedTitle in
                guard let selectedTitle = selectedTitle else { return nil }
                return String(localized: .localizable.flagUserSendToNosInfo(selectedTitle))
            },
            category: .privacy(.sendToNos)
        ),
        FlagOption(
            title: String(localized: .localizable.flagPubliclyTitle),
            description: String(localized: .localizable.flagPubliclyDescription),
            info: nil,
            category: .privacy(.publicly)
        )
    ]

    /// `FlagOption` instances representing different categories of the visibility of a flagged user.
    static let flagUserVisibilityOptions: [FlagOption] = [
        FlagOption(
            title: String(localized: .localizable.flagUserMuteTitle),
            description: String(localized: .localizable.flagUserMuteDescription),
            info: nil,
            category: .visibility(.mute)
        ),
        FlagOption(
            title: String(localized: .localizable.flagUserDontMuteTitle),
            description: String(localized: .localizable.flagUserDontMuteDescription),
            info: nil,
            category: .visibility(.dontMute)
        )
    ]

    static func == (lhs: FlagOption, rhs: FlagOption) -> Bool {
        lhs.id == rhs.id
    }
}

extension FlagOption {
    static let spam = FlagOption(
        title: String(localized: .localizable.flagContentSpamTitle),
        description: nil,
        info: nil,
        category: .report(ReportCategory.spam)
    )
    
    static let harassment = FlagOption(
        title: String(localized: .localizable.flagContentHarassmentTitle),
        description: String(localized: .localizable.flagContentHarassmentDescription),
        info: nil,
        category: .report(ReportCategory.harassment)
    )

    static let nsfw = FlagOption(
        title: "NSFW",
        description: String(localized: .localizable.flagContentNudityDescription),
        info: nil,
        category: .report(ReportCategory.nsfw)
    )

    static let illegal = FlagOption(
        title: String(localized: .localizable.flagContentIllegalTitle),
        description: String(localized: .localizable.flagContentIllegalDescription),
        info: nil,
        category: .report(ReportCategory.illegal)
    )

    static let impersonation = FlagOption(
        title: String(localized: .localizable.flagUserImpersonationTitle),
        description: String(localized: .localizable.flagUserImpersonationDescription),
        info: nil,
        category: .report(ReportCategory.other)
    )

    static let other = FlagOption(
        title: String(localized: .localizable.flagContentOtherTitle),
        description: String(localized: .localizable.flagContentOtherDescription),
        info: nil,
        category: .report(ReportCategory.other)
    )
}

/// Specifies the category associated with a specific flag.
enum FlagCategory {
    case report(ReportCategory)
    case privacy(SendFlagPrivacy)
    case visibility(FlagUserVisibility)
}

/// Specifies whether a flag should be sent privately to Nos or made public.
enum SendFlagPrivacy {
    case sendToNos
    case publicly
}

/// Specifies whether a flagged user should be muted or not.
enum FlagUserVisibility {
    case mute
    case dontMute
}
