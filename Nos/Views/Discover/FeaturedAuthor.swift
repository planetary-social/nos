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
    static let all = cohort5 + cohort4 + cohort3 + cohort2 + cohort1 + additionalAuthors
}

extension FeaturedAuthor {
    /// Additional authors to feature on the Discover tab who aren't part of a cohort.
    static let additionalAuthors = [
        FeaturedAuthor(
            name: "Rabble",
            npub: "npub1wmr34t36fy03m8hvgl96zl3znndyzyaqhwmwdtshwmtkg03fetaqhjg240",
            categories: [.activists, .tech]
        )
    ]
}

extension FeaturedAuthor {
    static let selectedNewAuthors = [
        FeaturedAuthor(
            name: "NOICE",
            npub: "npub1v02emwxjn2lznkmnszltjy4c7cqzxuejkmye0zeqs62wf0shpahswdmwuj",
            categories: [.art, .photography]
        ),
        FeaturedAuthor(
            name: "Wellington Chinese History",
            npub: "npub1fdyax3st9gcqj7zhqres3fw9pf7qrkukppv3fs7w2mcjcsqyrxjqcgcxcn",
            categories: [.nzAustralia]
        ),
        FeaturedAuthor(
            name: "Ignacio",
            npub: "npub1wptpq88jyjv6nwwltqx0exhxsg8zt0dcm4uwvtcxn80hxk2r66hswdm8rf",
            categories: [.lifestyle, .espanol]
        ),
        FeaturedAuthor(
            name: "Greenpeace Atoearoa",
            npub: "npub1mn78z9rssfq2yjqdwsa3h4qwu6zpw4xku9ppfldkde4ycwnpch4qhmcssl",
            categories: [.activists, .nzAustralia]
        ),
        FeaturedAuthor(
            name: "Bill Bennett",
            npub: "npub1gpcxn339ap3r9tju2uy6d5k8rmud7f8kr579w7zv54qyevgz9xsqdtr4us",
            categories: [.news, .nzAustralia]
        ),
        FeaturedAuthor(
            name: "The Spinoff",
            npub: "npub1qngl40pxy06k3hrqp4ltkn4p5yacen7u93du58v4tamf73tzaqhs6dfy8g",
            categories: [.news, .nzAustralia]
        ),
        FeaturedAuthor(
            name: "Dan Selvin",
            npub: "npub16jjukmhnvflj92dv2jr8z6udfhzyyuyf3mckmf6afws9w4xdhhzs745kmv",
            categories: [.news, .nzAustralia]
        ),
        FeaturedAuthor(
            name: "Nacho",
            npub: "npub1daajnadf0f0s7uz3yftur8434rtz2s949gkdpx7uyeapm9rlt0qq9q8w5z",
            categories: [.lifestyle]
        ),
        FeaturedAuthor(
            name: "Emma Cook",
            npub: "npub18pl5kgxl47e5pssxl9q38m2v7ez477gw3nz220jz2vslnjreqq8s2yxl9m",
            categories: [.art, .nzAustralia]
        ),
        FeaturedAuthor(
            name: "Jack Yan",
            npub: "npub179lhhjz30t3n4utkkn26qzgmpx44v9s5qdtwjs5686px8ulw7dfszxmfgp",
            categories: [.news, .nzAustralia]
        ),
        FeaturedAuthor(
            name: "Lucire",
            npub: "npub1l4s4mtt96znwu3plfeyupk37y63xfapw5e7kjn7uavuw02lvav5q3ngc3s",
            categories: [.news, .nzAustralia]
        ),
        FeaturedAuthor(
            name: "David Hood",
            npub: "npub12aew64q5lsxpcc98lskha0564gtjn30cw7vdueqnyj06xjqxtmksahdrlg",
            categories: [.nzAustralia, .news]
        ),
        FeaturedAuthor(
            name: "Kris Sowersby",
            npub: "npub1t6n8u5sa80m6sx53m7uge6afktek4me982wvclr3xe5tfeyg34fslkxqcz",
            categories: [.art, .nzAustralia]
        )
    ]
}
