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
            title: String(localized: "flagSendToNosTitle"),
            description: String(localized: "flagSendToNosDescription"),
            info: { selectedTitle in
                guard let selectedTitle = selectedTitle else { return nil }
                return String.localizedStringWithFormat(String(localized: "flagUserSendToNosInfo"), selectedTitle)
            },
            category: .privacy(.sendToNos)
        ),
        FlagOption(
            title: String(localized: "flagPubliclyTitle"),
            description: String(localized: "flagPubliclyDescription"),
            info: nil,
            category: .privacy(.publicly)
        )
    ]

    /// `FlagOption` instances representing different categories of how a user can be flagged.
    static let flagUserSendOptions: [FlagOption] = [
        FlagOption(
            title: String(localized: "flagSendToNosTitle"),
            description: String(localized: "flagSendToNosDescription"),
            info: { selectedTitle in
                guard let selectedTitle = selectedTitle else { return nil }
                return String.localizedStringWithFormat(String(localized: "flagUserSendToNosInfo"), selectedTitle)
            },
            category: .privacy(.sendToNos)
        ),
        FlagOption(
            title: String(localized: "flagPubliclyTitle"),
            description: String(localized: "flagPubliclyDescription"),
            info: nil,
            category: .privacy(.publicly)
        )
    ]

    /// `FlagOption` instances representing different categories of the visibility of a flagged user.
    static let flagUserVisibilityOptions: [FlagOption] = [
        FlagOption(
            title: String(localized: "flagUserMuteTitle"),
            description: String(localized: "flagUserMuteDescription"),
            info: nil,
            category: .visibility(.mute)
        ),
        FlagOption(
            title: String(localized: "flagUserDontMuteTitle"),
            description: String(localized: "flagUserDontMuteDescription"),
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
        title: String(localized: "flagContentSpamTitle"),
        description: nil,
        info: nil,
        category: .report(ReportCategory.spam)
    )
    
    static let harassment = FlagOption(
        title: String(localized: "flagContentHarassmentTitle"),
        description: String(localized: "flagContentHarassmentDescription"),
        info: nil,
        category: .report(ReportCategory.harassment)
    )

    static let nsfw = FlagOption(
        title: "NSFW",
        description: String(localized: "flagContentNudityDescription"),
        info: nil,
        category: .report(ReportCategory.nsfw)
    )

    static let illegal = FlagOption(
        title: String(localized: "flagContentIllegalTitle"),
        description: String(localized: "flagContentIllegalDescription"),
        info: nil,
        category: .report(ReportCategory.illegal)
    )

    static let impersonation = FlagOption(
        title: String(localized: "flagUserImpersonationTitle"),
        description: String(localized: "flagUserImpersonationDescription"),
        info: nil,
        category: .report(ReportCategory.other)
    )

    static let other = FlagOption(
        title: String(localized: "flagContentOtherTitle"),
        description: String(localized: "flagContentOtherDescription"),
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
