import Foundation

enum FeaturedAuthorCategory: CaseIterable {
    case all
    case new // swiftlint:disable:this identifier_name
    case journalists
    case tech
    case art // swiftlint:disable:this identifier_name
    case environment
    case sports
    case music

    var text: LocalizedStringResource {
        switch self {
        case .all: LocalizedStringResource.localizable.featuredAuthorCategoryAll
        case .new: LocalizedStringResource.localizable.featuredAuthorCategoryNew
        case .journalists: LocalizedStringResource.localizable.featuredAuthorCategoryJournalists
        case .tech: LocalizedStringResource.localizable.featuredAuthorCategoryTech
        case .art: LocalizedStringResource.localizable.featuredAuthorCategoryArt
        case .environment: LocalizedStringResource.localizable.featuredAuthorCategoryEnvironment
        case .sports: LocalizedStringResource.localizable.featuredAuthorCategorySports
        case .music: LocalizedStringResource.localizable.featuredAuthorCategoryMusic
        }
    }

    var npubs: [String] {
        switch self {
        case .all:
            Array(FeaturedAuthorCategory.npubsToCategories.keys)
        default:
            FeaturedAuthorCategory.npubsToCategories
                .filter { npubToCategories in
                    npubToCategories.value.contains(self)
                }
                .map { $0.key }
        }
    }

    static let npubsToCategories: [String: [FeaturedAuthorCategory]] = [
        "npub1asuq0pxedwfagpqkdf4lrfmcyfaffgptmayel9947j8krad3x58srs20ap": [.new, .music],
        "npub1d9nndmy3lx6f00cysrmn2v9t6hz280uwycw0kgcfdhvg99azry8sududfv": [.journalists, .tech],
        "npub1grz7afdguc67jkjly6fu0xmw0r386t8mtxafutu9u34dy207nt9ql335cv": [.journalists, .tech],
        "npub1yxzkmtuyctjw2pffp6e9uvyrkp29hrqra2tm3xp3z9707z06muxsg75qvv": [.tech],
        "npub1d7ggne0xsy8e2999q8cyh9zxda688axm07cwncufjeku0nahvfgsyz6qzr": [.art],
        "npub17a49ajzjlwjv4znh85jcfgmk7qq5ck8m5advx66rudz8g0v034kss2hnk3": [.art],
        "npub1l9kr6ajfwp6vfjp60vuzxwqwwlw884dff98a9cznujs520shsf9s35xfwh": [.art],
        "npub1uh8e4y97tvs5zhsq6srr43qy0u66zk8xfy08xcrhef2803sdfcrslq62el": [.environment],
        "npub1aylzctp5p20yc842qfpu2w9j8q0kpqcfx8q3p42ugnp3t8uxg3xq3k8nn0": [.sports],
    ]
}
