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
    case music
    case news
    case art // swiftlint:disable:this identifier_name
    case activists
    case tech
    case health
    case gaming
    case sports

    var text: LocalizedStringKey {
        switch self {
        case .all: "featuredAuthorCategoryAll"
        case .new: "featuredAuthorCategoryNew"
        case .music: "featuredAuthorCategoryMusic"
        case .news: "featuredAuthorCategoryNews"
        case .art: "featuredAuthorCategoryArt"
        case .activists: "featuredAuthorCategoryActivists"
        case .gaming: "featuredAuthorCategoryGaming"
        case .sports: "featuredAuthorCategorySports"
        case .tech: "featuredAuthorCategoryTech"
        case .health: "featuredAuthorCategoryHealth"
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
