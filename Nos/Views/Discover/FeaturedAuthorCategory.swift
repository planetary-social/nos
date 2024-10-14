import Foundation

/// Categories of featured authors on the Discover tab.
/// - Note: The order of cases in this enum determines the order in which categories are displayed
///         on the Discover tab.
enum FeaturedAuthorCategory: CaseIterable {
    /// A special type of category that includes all other categories.
    case all
    /// A special type of category that includes all authors from the latest cohort.
    case new  // swiftlint:disable:this identifier_name
    case music
    case news
    case art  // swiftlint:disable:this identifier_name
    case activists
    case tech
    case health
    case gaming
    case sports

    var text: LocalizedStringResource {
        switch self {
        case .all: LocalizedStringResource.localizable.featuredAuthorCategoryAll
        case .new: LocalizedStringResource.localizable.featuredAuthorCategoryNew
        case .music: LocalizedStringResource.localizable.featuredAuthorCategoryMusic
        case .news: LocalizedStringResource.localizable.featuredAuthorCategoryNews
        case .art: LocalizedStringResource.localizable.featuredAuthorCategoryArt
        case .activists: LocalizedStringResource.localizable.featuredAuthorCategoryActivists
        case .gaming: LocalizedStringResource.localizable.featuredAuthorCategoryGaming
        case .sports: LocalizedStringResource.localizable.featuredAuthorCategorySports
        case .tech: LocalizedStringResource.localizable.featuredAuthorCategoryTech
        case .health: LocalizedStringResource.localizable.featuredAuthorCategoryHealth
        }
    }

    var featuredAuthors: [FeaturedAuthor] {
        switch self {
        case .all:
            FeaturedAuthor.all
        case .new:
            FeaturedAuthor.cohort4
        default:
            FeaturedAuthor.all.filter { $0.categories.contains(self) }
        }
    }

    var rawIDs: [RawNostrID] {
        featuredAuthors.map { $0.rawID }
    }
}
