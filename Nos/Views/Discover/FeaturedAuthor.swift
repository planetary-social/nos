import Foundation

/// An author that's featured on the Discover tab.
/// - Note: This is not related to the `Author` Core Data model. This is simply a lightweight type used to
///         specify which authors appear on the Discover tab.
struct FeaturedAuthor {
    /// A name, used for internal purposes, to make it easier to distinguish between featured authors.
    /// Not used or displayed anywhere; this is purely to prevent bugs via code readability.
    let name: String
    /// The public key (npub) of the author.
    let npub: String
    /// The categories in which to show the author on the Discover tab.
    /// No need to include the `.all` category; that's done automatically.
    let categories: [FeaturedAuthorCategory]
}

extension FeaturedAuthor {
    /// All featured authors that should appear on the Discover tab.
    static let all = cohort2 + cohort1
}

extension FeaturedAuthor {
    /// The first cohort of authors to display on the Discover tab.
    static let cohort1 = [
        FeaturedAuthor(
            name: "Miguel Almodo",
            npub: "npub1ajt9gp0prf4xrp4j07j9rghlcyukahncs0fw5ywr977jccued9nqrcc0cs",
            categories: [.activists]
        ),
        FeaturedAuthor(
            name: "The Conversation",
            npub: "npub1uuxnz0sq60thc098xfxqst7wnw77l0sm3r8nn48yspuvz4ecprksxdahzv",
            categories: [.news]
        ),
        FeaturedAuthor(
            name: "Nela Biedermann",
            npub: "npub1fv9u4drq4hdrr7k45vn0krqy7mkgy8ajf059m0wq8szvcrsjlsrs8tdz3p",
            categories: [.art]
        ),
        FeaturedAuthor(
            name: "Ainsley Costello",
            npub: "npub13qrrw2h4z52m7jh0spefrwtysl4psfkfv6j4j672se5hkhvtyw7qu0almy",
            categories: [.music]
        ),
        FeaturedAuthor(
            name: "Chris Liss",
            npub: "npub1dwhr8j9uy6ju2uu39t6tj6mw76gztr4rwdd6jr9qtkdh5crjwt5q2nqfxe",
            categories: [.sports]
        ),
        FeaturedAuthor(
            name: "Alicia Stockman",
            npub: "npub1l3y60kjywvrrln5ftse553h2ltg53sm3zy55grvlncd78x3k5uqsmw8dff",
            categories: [.music]
        ),
        FeaturedAuthor(
            name: "Judson McKinney and the Wanderers",
            npub: "npub1jvt2hacqqzvwjkum30mlvmy52jer4p4crfh0veqstpk58rr9e7ms2fwh74",
            categories: [.music]
        ),
        FeaturedAuthor(
            name: "Onigirl",
            npub: "npub18jvyjwpmm65g8v9azmlvu8knd5m7xlxau08y8vt75n53jtkpz2ys6mqqu3",
            categories: [.art]
        ),
        FeaturedAuthor(
            name: "Black in Aquatics",
            npub: "npub1ee852umhw26afdfwgf90cky9ufaythwyarttqu59lazcrx56z0tsmx3mkz",
            categories: [.sports]
        ),
        FeaturedAuthor(
            name: "Global Sports Central",
            npub: "npub1qspus6smkn8mcdxg5jflh50s69vdgtwsd5p74gmjpzp2qekn5duqfv5afj",
            categories: [.news, .sports]
        ),
        FeaturedAuthor(
            name: "Alastair Thompson",
            npub: "npub157pk8t8njtnldqzankrk2syzmkp6qtrv2ewgq3fnuc4k78dr797shfngev",
            categories: [.news]
        ),
    ]
}

extension FeaturedAuthor {
    static let cohort2 = [
        FeaturedAuthor(
            name: "Lou",
            npub: "npub1rr3678k7ajms2sht0cqqeawy86sdd5ahn6akfj8zex9ng82zuh0sz8nywd",
            categories: [.gaming]
        ),
        FeaturedAuthor(
            name: "We Distribute",
            npub: "npub1w9wuqc3s6lr25c4sgj52werj3tngvt43qrccqrher4wvn7tjm32s2ck403",
            categories: [.news, .tech]
        ),
        FeaturedAuthor(
            name: "Simon Howard",
            npub: "npub1rt5h26ukmqsqa29ggt0h98tq2skgqr85f3znhwxule4z4pjhhd3qzs5k94",
            categories: [.music]
        ),
        FeaturedAuthor(
            name: "The 74 Million",
            npub: "npub1kkk52065zqg85c0auvashalkrqewj6cnlr7c236r2hp5sx9rgzgs46gj84",
            categories: [.news]
        ),
        FeaturedAuthor(
            name: "BTCPhoto",
            npub: "npub1vjl6n2llukcc6pe3am2hkwqh8twzh2ymlp7pdrdfq5tlqg08y26sd7ygzx",
            categories: [.art]
        ),
        FeaturedAuthor(
            name: "Sam Hain",
            npub: "npub1df47g7a39usamq83aula72zdz23fx9xw5rrfmd0v6p9t20n5u0ss2eqez9",
            categories: [.art]
        ),
        FeaturedAuthor(
            name: "Joanna",
            npub: "npub1a2a85jwde32zjsjk02ujasydqc3t2w9rfgfe97amm0r4d9mepfxsxf3fnn",
            categories: [.activists, .health]
        ),
        FeaturedAuthor(
            name: "Josh Brown",
            npub: "npub1yl8jc6znttslcpj3p6p8vuq98awu6w0xh4lqtu0lkjr772kpx4ysfqvz34",
            categories: [.art]
        ),
    ]
}
