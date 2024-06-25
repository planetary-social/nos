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
    
    let rawID: RawAuthorID
    
    init(name: String, npub: String, categories: [FeaturedAuthorCategory]) {
        self.name = name
        self.npub = npub
        self.categories = categories
        
        guard let rawID = PublicKey(npub: npub)?.hex else {
            assertionFailure("A FeaturedAuthor has a invalid npub: \(npub)")
            self.rawID = ""
            return
        } 
        self.rawID = rawID
    }
}

extension FeaturedAuthor {
    /// All featured authors that should appear on the Discover tab.
    static let all = cohort3 + cohort2 + cohort1
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

extension FeaturedAuthor {
    static let cohort3 = [
        FeaturedAuthor(
            name: "INPC",
            npub: "npub1q33jywkl8r0e5g48lvrenxnr3lw59kzrw4e7p0cecslqzwc56eesjymqu0",
            categories: [.music]
        ),
        FeaturedAuthor(
            name: "Mama Ganush",
            npub: "npub1lq9lx5mh2m3pvdnckcta7h7h07qexa3gxvyakdzt73lqp3prt3jqx9pa2e",
            categories: [.activists]
        ),
        FeaturedAuthor(
            name: "Fight for the Future",
            npub: "npub1jcwuf0dh5vqsq44qavygqwjfecawf53fmx7gadlcdtuexz0548hqy4jyrz",
            categories: [.activists, .tech]
        ),
        FeaturedAuthor(
            name: "Z Network",
            npub: "npub1xm0rvnpw52nh7tk59ntly55w74rmd2cqvt3kg5zxrzz3rlssvspsk0gs6s",
            categories: [.news, .activists]
        ),
        FeaturedAuthor(
            name: "Z Network Chomsky",
            npub: "npub1a7mxreazql8ld0csdzk7wk6a5xjzcg7h632q78u3008lyr32lxks5t4ske",
            categories: [.activists]
        ),
        FeaturedAuthor(
            name: "Patrick Boehler",
            npub: "npub1n8gvnx827tdl46ke406sjx0t5ey4mrtptux766ejp9y2ff8cc3uqe4ufd0",
            categories: [.news, .tech]
        ),
        FeaturedAuthor(
            name: "JSTR",
            npub: "npub1vpdlxsc8dr4m580d43vj4ka0e6wmstzzxhvcermllhh5m9ytnhdq6wnaem",
            categories: [.music]
        ),
    ]
}
