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
    static let all = cohort1
}

extension FeaturedAuthor {
    /// The first cohort of authors to display on the Discover tab.
    static let cohort1 = [
        FeaturedAuthor(
            name: "Mark Cubey",
            npub: "npub1j9gcqjheu50kyzkjjmh3pq0msknh58sxu6ugsp33hxfwf5a78r3sfx59e7",
            categories: [.news]
        ),
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
            name: "Lou",
            npub: "npub1rr3678k7ajms2sht0cqqeawy86sdd5ahn6akfj8zex9ng82zuh0sz8nywd",
            categories: [.gaming]
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
            name: "Jacob Gardenswartz",
            npub: "npub1cjvqtcla069ctrkapc9yhzp3xhph29khhz0x7ype7dgfwljcwc8savma9c",
            categories: [.news]
        ),
        FeaturedAuthor(
            name: "Global Sports Central",
            npub: "npub1qspus6smkn8mcdxg5jflh50s69vdgtwsd5p74gmjpzp2qekn5duqfv5afj",
            categories: [.news, .sports]
        ),
        FeaturedAuthor(
            name: "Alastair Thompson",
            npub: "npub157pk8t8njtnldqzankrk2syzmkp6qtrv2ewgq3fnuc4k78dr797shfngev",
            categories: [.news, .sports]
        ),
    ]
}
