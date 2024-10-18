import Foundation
import SwiftUI

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
    case nzAustralia
    case photography
    case politics
    case random
    case sciFi
    case sports
    case tech

    var text: LocalizedStringKey {
        switch self {
        case .all: "featuredAuthorCategoryAll"
        case .new: "featuredAuthorCategoryNew"
        case .activists: "featuredAuthorCategoryActivists"
        case .art: "featuredAuthorCategoryArt"
        case .espanol: "featuredAuthorCategoryEspanol"
        case .food: "featuredAuthorCategoryFood"
        case .gaming: "featuredAuthorCategoryGaming"
        case .health: "featuredAuthorCategoryHealth"
        case .lifestyle: "featuredAuthorCategoryLifestyle"
        case .music: "featuredAuthorCategoryMusic"
        case .news: "featuredAuthorCategoryNews"
        case .nzAustralia: "featuredAuthorCategoryNZAustralia"
        case .photography: "featuredAuthorCategoryPhotography"
        case .politics: "featuredAuthorCategoryPolitics"
        case .random: "featuredAuthorCategoryRandom"
        case .sciFi: "featuredAuthorCategorySciFi"
        case .sports: "featuredAuthorCategorySports"
        case .tech: "featuredAuthorCategoryTech"
        }
    }

    var featuredAuthors: [FeaturedAuthor] {
        switch self {
        case .all:
            FeaturedAuthor.all
        case .new:
            FeaturedAuthor.selectedNewAuthors
        default:
            FeaturedAuthor.all.filter { $0.categories.contains(self) }
        }
    }

    var rawIDs: [RawNostrID] {
        featuredAuthors.map { $0.rawID }
    }
}
