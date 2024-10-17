import Foundation

/// Categories of featured authors on the Discover tab.
/// - Note: The order of cases in this enum determines the order in which categories are displayed
///         on the Discover tab.
enum FeaturedAuthorCategory: CaseIterable {
    /// A special type of category that includes all other categories.
    case all
    /// A special type of category that includes all authors from the latest cohort.
    case new // swiftlint:disable:this identifier_name
    case activists
    case art // swiftlint:disable:this identifier_name
    case espanol
    case food
    case gaming
    case health
    case lifestyle
    case music
    case news
    case newzealand
    case photography
    case politics
    case random
    case scifi
    case sports
    case tech

    var text: LocalizedStringResource {
        switch self {
        case .all: LocalizedStringResource.localizable.featuredAuthorCategoryAll
        case .new: LocalizedStringResource.localizable.featuredAuthorCategoryNew
        case .activists: LocalizedStringResource.localizable.featuredAuthorCategoryActivists
        case .art: LocalizedStringResource.localizable.featuredAuthorCategoryArt
        case .espanol: "featuredAuthorCategoryEspanol"
        case .food: "featuredAuthorCategoryFood"
        case .gaming: LocalizedStringResource.localizable.featuredAuthorCategoryGaming
        case .health: LocalizedStringResource.localizable.featuredAuthorCategoryHealth
        case .lifestyle: "featuredAuthorCategoryLifestyle"
        case .music: LocalizedStringResource.localizable.featuredAuthorCategoryMusic
        case .news: LocalizedStringResource.localizable.featuredAuthorCategoryNews
        case .newzealand: "featuredAuthorCategoryNewzealand"
        case .photography: "featuredAuthorCategoryPhotography"
        case .politics: "featuredAuthorCategoryPolitics"
        case .random: "featuredAuthorCategoryRandom"
        case .scifi: "featuredAuthorCategoryScifi"
        case .sports: LocalizedStringResource.localizable.featuredAuthorCategorySports
        case .tech: LocalizedStringResource.localizable.featuredAuthorCategoryTech
        }
    }

    var featuredAuthors: [FeaturedAuthor] {
        switch self {
        case .all:
            FeaturedAuthor.all
        case .new:
            FeaturedAuthor.selectNew
        default:
            FeaturedAuthor.all.filter { $0.categories.contains(self) }
        }
    }

    var rawIDs: [RawNostrID] {
        featuredAuthors.map { $0.rawID }
    }
}
