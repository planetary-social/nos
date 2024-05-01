import Foundation

/// Categories of featured authors on the Discover tab.
/// The order of cases in this enum determines the order in which categories are displayed on the Discover tab.
enum FeaturedAuthorCategory: CaseIterable {
    /// A special type of category that includes all other categories.
    case all
    case new // swiftlint:disable:this identifier_name
    case activists
    case news
    case gaming
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
        case .activists: LocalizedStringResource.localizable.featuredAuthorCategoryActivists
        case .news: LocalizedStringResource.localizable.featuredAuthorCategoryNews
        case .gaming: LocalizedStringResource.localizable.featuredAuthorCategoryGaming
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
        "npub1ajt9gp0prf4xrp4j07j9rghlcyukahncs0fw5ywr977jccued9nqrcc0cs": [.activists],
        "npub1uuxnz0sq60thc098xfxqst7wnw77l0sm3r8nn48yspuvz4ecprksxdahzv": [.news],
        "npub1fv9u4drq4hdrr7k45vn0krqy7mkgy8ajf059m0wq8szvcrsjlsrs8tdz3p": [.art],
        "npub13qrrw2h4z52m7jh0spefrwtysl4psfkfv6j4j672se5hkhvtyw7qu0almy": [.music],
        "npub1dwhr8j9uy6ju2uu39t6tj6mw76gztr4rwdd6jr9qtkdh5crjwt5q2nqfxe": [.sports],
        "npub1kw97r9hkcd475cdsqemzh70pwk9vn7qq64ggu2gkgrfnz559kcvqygtr6m": [.activists],
        "npub1l3y60kjywvrrln5ftse553h2ltg53sm3zy55grvlncd78x3k5uqsmw8dff": [.music],
        "npub1jvt2hacqqzvwjkum30mlvmy52jer4p4crfh0veqstpk58rr9e7ms2fwh74": [.music],
        "npub1rr3678k7ajms2sht0cqqeawy86sdd5ahn6akfj8zex9ng82zuh0sz8nywd": [.gaming],
        "npub18jvyjwpmm65g8v9azmlvu8knd5m7xlxau08y8vt75n53jtkpz2ys6mqqu3": [.art],
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
