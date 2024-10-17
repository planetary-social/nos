// swiftlint:disable file_length
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
        ),
        FeaturedAuthor(
            name: "Edward Snowden",
            npub: "npub1sn0wdenkukak0d9dfczzeacvhkrgz92ak56egt7vdgzn8pv2wfqqhrjdv9",
            categories: [.activists, .tech]
        ),
    ]
}

extension FeaturedAuthor {
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
            name: "Black in Aquatics",
            npub: "npub1ee852umhw26afdfwgf90cky9ufaythwyarttqu59lazcrx56z0tsmx3mkz",
            categories: [.sports]
        ),
        FeaturedAuthor(
            name: "Global Sports Central",
            npub: "npub1qspus6smkn8mcdxg5jflh50s69vdgtwsd5p74gmjpzp2qekn5duqfv5afj",
            categories: [.news, .sports]
        )
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

extension FeaturedAuthor {
    static let cohort4 = [
        FeaturedAuthor(
            name: "Existing Sprinkles",
            npub: "npub1f5kc2agn63ecv2ua4909z9ahgmr2x9263na36jh6r908ql0926jq3nvk2u",
            categories: [.art]
        ),
        FeaturedAuthor(
            name: "ArchJourney",
            npub: "npub1qhjxfxpjm7udr0agr6nuhuwf9383e4g9907g64r9hf6y4fh6t6uqpcp36k",
            categories: [.art]
        ),
        FeaturedAuthor(
            name: "Neigsendoig Cocules",
            npub: "npub1372csjhjv35sxcqm90ca2d0cfxsl6xku7j6hhswynwdy9m7zl98scn950w",
            categories: [.music]
        ),
        FeaturedAuthor(
            name: "Lexie Bean",
            npub: "npub1s8c5mk68qn0erxrx5waqz7xxk39x5xx2367879eqcv270tqs4tvsf5ewgf",
            categories: [.activists]
        ),
        FeaturedAuthor(
            name: "Protest.net",
            npub: "npub1z3thwmwasmp787zvk2aaq5qdjtjdkl637p52nph4flv668973c8qaz2du7",
            categories: [.activists]
        ),
    ]
}

extension FeaturedAuthor {
    static let cohort5 = [
        FeaturedAuthor(
            name: "kindness project bot",
            npub: "npub1r8yz465alvfnykhkfula8kxxeas2z75hats0tymw8yv3kp0p4a5qp6phl8",
            categories: [.health]
        ),
        FeaturedAuthor(
            name: "Pegah",
            npub: "npub1rt65j4vnd05qf72szpj8afdd5hrkylka7pe55lup8waquv0wm9sqjj0y9g",
            categories: [.art]
        ),
        FeaturedAuthor(
            name: "Karine Studio",
            npub: "npub1l9kr6ajfwp6vfjp60vuzxwqwwlw884dff98a9cznujs520shsf9s35xfwh",
            categories: [.art]
        ),
        FeaturedAuthor(
            name: "Kavinya",
            npub: "npub1w3myuqcf6gzgluqtn0mzpmqyqyqlzhtrhdsna8t287mggjg9j6zs2xjh9z",
            categories: [.music]
        ),
        FeaturedAuthor(
            name: "NOICE",
            npub: "npub1v02emwxjn2lznkmnszltjy4c7cqzxuejkmye0zeqs62wf0shpahswdmwuj",
            categories: [.art, .photography]
        ),
        FeaturedAuthor(
            name: "Matt Birchler",
            npub: "npub13huwfylt3hm77wxk9js63k0y3p03u3xhj39z49hnkdcydvp0ph6sr573xv",
            categories: [.tech]
        ),
        FeaturedAuthor(
            name: "John Gruber",
            npub: "npub19tmpp2jx64y4ggf9d7gyjdvtrjckx4udjal4sc77s62sfm3cfslqmkc8af",
            categories: [.tech]
        ),
        FeaturedAuthor(
            name: "Meredith Whittaker",
            npub: "npub15s3hussvmv9nyvw3w8lg0x72udazmdat7tcj5vmmjafnwcvv8tpqzz6r6y",
            categories: [.tech]
        ),
        FeaturedAuthor(
            name: "Charles Stross",
            npub: "npub1yacj26q9parem5fqf2s3ym9xkxghkk0w2jc63aglsnl2fmyhshnszgla7e",
            categories: [.scifi]
        ),
        FeaturedAuthor(
            name: "Pablonius Monk",
            npub: "npub1cxl7dfnmy669w65uyc27f0kwwg0p8dgfz9h2w36jpt7q90v99wcqpluwyu",
            categories: [.politics]
        ),
        FeaturedAuthor(
            name: "Taylor Lorenz",
            npub: "npub1d9nndmy3lx6f00cysrmn2v9t6hz280uwycw0kgcfdhvg99azry8sududfv",
            categories: [.tech]
        ),
        FeaturedAuthor(
            name: "zed-erwan",
            npub: "npub1r2sah0htqnw7xrs70gq00m48vp25neu8ym2n2ghrny92dqqf7sest8hth0",
            categories: [.art]
        ),
        FeaturedAuthor(
            name: "Franny",
            npub: "npub1995y964wmxl94crx3ksfley24szjr390skdd237ex9z7ttp5c9lqld8vtf",
            categories: [.photography]
        ),
        FeaturedAuthor(
            name: "Johanna",
            npub: "npub1a2a85jwde32zjsjk02ujasydqc3t2w9rfgfe97amm0r4d9mepfxsxf3fnn",
            categories: [.health]
        ),
        FeaturedAuthor(
            name: "Alisa",
            npub: "npub1q4e23x480fcn2wpxh7ufl8h2mtd06g0ynjdeaqjgqtkn2pae2awsd95ftj",
            categories: [.food]
        ),
        FeaturedAuthor(
            name: "ProPublica",
            npub: "npub19fwwstv5dg8qsmuj9rmgf98nt9lfz5gvv67jqx6y9jtgekpcz5pqpgulzp",
            categories: [.news]
        ),
        FeaturedAuthor(
            name: "Robert Reich",
            npub: "npub1dzkq7f7q23fh0mrw03wwd23ddmu258k6m34gctl6ark6qlex4l7qskqcce",
            categories: [.news]
        ),
        FeaturedAuthor(
            name: "Internet Archive",
            npub: "npub13f3xuy2npzmpctnv3z4c0rte3ntsl7kflwcrkt97zrltlq68d5ws0pfd3f",
            categories: [.news]
        ),
        FeaturedAuthor(
            name: "Electronic Frontier Foundation",
            npub: "npub1q40jtk09x6mdmmlw09qracctqpgsr9zl2hcc7wzf8vuwasqsncwsxgaa27",
            categories: [.news]
        ),
        FeaturedAuthor(
            name: "Eliza",
            npub: "npub1yye4qu6qrgcsejghnl36wl5kvecsel0kxr0ass8ewtqc8gjykxkssdhmd0",
            categories: [.art]
        ),
        FeaturedAuthor(
            name: "MLS Major League Soccer",
            npub: "npub1tql0248ettpuxngcmyqqt7q83zacx4ajxg3kv35ptayzd3nw2jnqxnwxsu",
            categories: [.sports]
        ),
        FeaturedAuthor(
            name: "Ava",
            npub: "npub1f6ugxyxkknket3kkdgu4k0fu74vmshawermkj8d06sz6jts9t4kslazcka",
            categories: [.tech]
        ),
        FeaturedAuthor(
            name: "Eva",
            npub: "npub18wn0jd3p7n6u3y7mc46p0hpx3cmtv9k3mu82rc0lhkg3rdyf590s3wshpx",
            categories: [.tech, .activists]
        ),
        FeaturedAuthor(
            name: "Strypey",
            npub: "npub1pwwm8s9zxssfm3aqv3g4fvqfh9kglr76m5z434cymju9gp9jhwwqdqtc65",
            categories: [.tech, .activists]
        ),
        FeaturedAuthor(
            name: "Cecilia",
            npub: "npub1paftqx5zvj0gjtu3whudejxdgv4vdn27paw4lzaauc43kgfxxaqs75c5a7",
            categories: [.art]
        ),
        FeaturedAuthor(
            name: "Alvin",
            npub: "npub1ansj0chcjdksv5m83lkshkyah5jxky6uqupgtphemsr27azm4wwqz0epd5",
            categories: [.tech, .espanol]
        ),
        FeaturedAuthor(
            name: "Zoé",
            npub: "npub16wy27uj48r82gskq48uvxku8076h0y9xcngsgry7j4yn6zxmnznqu4hy6a",
            categories: [.photography, .espanol]
        ),
        FeaturedAuthor(
            name: "Melvin Carvalho",
            npub: "npub1melv683fw6n2mvhl5h6dhqd8mqfv3wmxnz4qph83ua4dk4006ezsrt5c24",
            categories: [.tech]
        ),
        FeaturedAuthor(
            name: "Just Loud",
            npub: "npub1a377f258tzafuzdgezwjw4aplg8ze3suyzm40t6j4czcjvwp5vls5d5r4w",
            categories: [.music]
        ),
        FeaturedAuthor(
            name: "Paloma",
            npub: "npub1gscnk7wlcvcruw7scjhwpjrja94gfu369fzkyje6kcc0yn6rqyhscqtpjp",
            categories: [.lifestyle]
        ),
        FeaturedAuthor(
            name: "Cory doctorow",
            npub: "npub1yxzkmtuyctjw2pffp6e9uvyrkp29hrqra2tm3xp3z9707z06muxsg75qvv",
            categories: [.tech, .activists]
        ),
        FeaturedAuthor(
            name: "Sitko",
            npub: "npub12rze589jx0gg6kslkjfl2gxxkhtlw73t5shyve5qrglrv6c2qflqejj7ns",
            categories: [.photography]
        ),
        FeaturedAuthor(
            name: "Ratel",
            npub: "npub15c3sa5kzedkfys95mc5egmst8ptuqefvezemae0883un7hqf5d5sgmqlxf",
            categories: [.art]
        ),
        FeaturedAuthor(
            name: "Wellington Chinese History",
            npub: "npub1fdyax3st9gcqj7zhqres3fw9pf7qrkukppv3fs7w2mcjcsqyrxjqcgcxcn",
            categories: [.newzealand]
        ),
        FeaturedAuthor(
            name: "David Hood",
            npub: "npub12aew64q5lsxpcc98lskha0564gtjn30cw7vdueqnyj06xjqxtmksahdrlg",
            categories: [.newzealand, .news]
        ),
        FeaturedAuthor(
            name: "Kris Sowersby",
            npub: "npub1t6n8u5sa80m6sx53m7uge6afktek4me982wvclr3xe5tfeyg34fslkxqcz",
            categories: [.art, .newzealand]
        ),
        FeaturedAuthor(
            name: "Greenpeace Atoearoa",
            npub: "npub1mn78z9rssfq2yjqdwsa3h4qwu6zpw4xku9ppfldkde4ycwnpch4qhmcssl",
            categories: [.activists, .newzealand]
        ),
        FeaturedAuthor(
            name: "Bill Bennett",
            npub: "npub1gpcxn339ap3r9tju2uy6d5k8rmud7f8kr579w7zv54qyevgz9xsqdtr4us",
            categories: [.news, .newzealand]
        ),
        FeaturedAuthor(
            name: "The Spinoff",
            npub: "npub1qngl40pxy06k3hrqp4ltkn4p5yacen7u93du58v4tamf73tzaqhs6dfy8g",
            categories: [.news, .newzealand]
        ),
        FeaturedAuthor(
            name: "Dan Selvin",
            npub: "npub16jjukmhnvflj92dv2jr8z6udfhzyyuyf3mckmf6afws9w4xdhhzs745kmv",
            categories: [.news, .newzealand]
        ),
        FeaturedAuthor(
            name: "Emma Cook",
            npub: "npub18pl5kgxl47e5pssxl9q38m2v7ez477gw3nz220jz2vslnjreqq8s2yxl9m",
            categories: [.art, .newzealand]
        ),
        FeaturedAuthor(
            name: "Jack Yan",
            npub: "npub179lhhjz30t3n4utkkn26qzgmpx44v9s5qdtwjs5686px8ulw7dfszxmfgp",
            categories: [.news, .newzealand]
        ),
        FeaturedAuthor(
            name: "Lucire",
            npub: "npub1l4s4mtt96znwu3plfeyupk37y63xfapw5e7kjn7uavuw02lvav5q3ngc3s",
            categories: [.news, .newzealand]
        ),
        FeaturedAuthor(
            name: "Ian Griffin",
            npub: "npub19p6edn6lvz9dmegm7s8vyz9w5w0ejzgztke8rcswxgmqr35h8feszt36jc",
            categories: [.scifi, .newzealand]
        ),
        FeaturedAuthor(
            name: "JSM",
            npub: "npub1uqeexjx2djkfwzxdnrnrrch5h2k4xn0uapcgsxm94ftaxrlhy5lqywjckg",
            categories: [.tech]
        ),
        FeaturedAuthor(
            name: "Carla",
            npub: "npub1hu3hdctm5nkzd8gslnyedfr5ddz3z547jqcl5j88g4fame2jd08qh6h8nh",
            categories: [.random]
        ),
        FeaturedAuthor(
            name: "Wavlake",
            npub: "npub1yfg0d955c2jrj2080ew7pa4xrtj7x7s7umt28wh0zurwmxgpyj9shwv6vg",
            categories: [.music]
        ),
        FeaturedAuthor(
            name: "Angela",
            npub: "npub19vvkfwy9mcluhvehw7r56p4stsj5lmx4v9g3vgkwsm3arpgef8aqsrt562",
            categories: [.random]
        ),
        FeaturedAuthor(
            name: "J",
            npub: "npub1fv9u4drq4hdrr7k45vn0krqy7mkgy8ajf059m0wq8szvcrsjlsrs8tdz3p",
            categories: [.food, .random]
        ),
        FeaturedAuthor(
            name: "Connie",
            npub: "npub1468024mrwz6uhywjvt8s6vw4e604egnv8tfd2m2utrmqyd3nu3fsutvgjn",
            categories: [.random]
        ),
        FeaturedAuthor(
            name: "Ignacio",
            npub: "npub1wptpq88jyjv6nwwltqx0exhxsg8zt0dcm4uwvtcxn80hxk2r66hswdm8rf",
            categories: [.lifestyle, .espanol]
        ),
        FeaturedAuthor(
            name: "Nacho",
            npub: "npub1daajnadf0f0s7uz3yftur8434rtz2s949gkdpx7uyeapm9rlt0qq9q8w5z",
            categories: [.lifestyle]
        )
    ]
}

extension FeaturedAuthor {
    static let selectNew = [
        FeaturedAuthor(
            name: "NOICE",
            npub: "npub1v02emwxjn2lznkmnszltjy4c7cqzxuejkmye0zeqs62wf0shpahswdmwuj",
            categories: [.art, .photography]
        ),
        FeaturedAuthor(
            name: "Wellington Chinese History",
            npub: "npub1fdyax3st9gcqj7zhqres3fw9pf7qrkukppv3fs7w2mcjcsqyrxjqcgcxcn",
            categories: [.newzealand]
        ),
        FeaturedAuthor(
            name: "Ignacio",
            npub: "npub1wptpq88jyjv6nwwltqx0exhxsg8zt0dcm4uwvtcxn80hxk2r66hswdm8rf",
            categories: [.lifestyle, .espanol]
        ),
        FeaturedAuthor(
            name: "Greenpeace Atoearoa",
            npub: "npub1mn78z9rssfq2yjqdwsa3h4qwu6zpw4xku9ppfldkde4ycwnpch4qhmcssl",
            categories: [.activists, .newzealand]
        ),
        FeaturedAuthor(
            name: "Bill Bennett",
            npub: "npub1gpcxn339ap3r9tju2uy6d5k8rmud7f8kr579w7zv54qyevgz9xsqdtr4us",
            categories: [.news, .newzealand]
        ),
        FeaturedAuthor(
            name: "The Spinoff",
            npub: "npub1qngl40pxy06k3hrqp4ltkn4p5yacen7u93du58v4tamf73tzaqhs6dfy8g",
            categories: [.news, .newzealand]
        ),
        FeaturedAuthor(
            name: "Dan Selvin",
            npub: "npub16jjukmhnvflj92dv2jr8z6udfhzyyuyf3mckmf6afws9w4xdhhzs745kmv",
            categories: [.news, .newzealand]
        ),
        FeaturedAuthor(
            name: "Nacho",
            npub: "npub1daajnadf0f0s7uz3yftur8434rtz2s949gkdpx7uyeapm9rlt0qq9q8w5z",
            categories: [.lifestyle]
        ),
        FeaturedAuthor(
            name: "Emma Cook",
            npub: "npub18pl5kgxl47e5pssxl9q38m2v7ez477gw3nz220jz2vslnjreqq8s2yxl9m",
            categories: [.art, .newzealand]
        ),
        FeaturedAuthor(
            name: "Jack Yan",
            npub: "npub179lhhjz30t3n4utkkn26qzgmpx44v9s5qdtwjs5686px8ulw7dfszxmfgp",
            categories: [.news, .newzealand]
        ),
        FeaturedAuthor(
            name: "Lucire",
            npub: "npub1l4s4mtt96znwu3plfeyupk37y63xfapw5e7kjn7uavuw02lvav5q3ngc3s",
            categories: [.news, .newzealand]
        ),
        FeaturedAuthor(
            name: "Ian Griffin",
            npub: "npub19p6edn6lvz9dmegm7s8vyz9w5w0ejzgztke8rcswxgmqr35h8feszt36jc",
            categories: [.scifi, .newzealand]
        ),
        FeaturedAuthor(
            name: "David Hood",
            npub: "npub12aew64q5lsxpcc98lskha0564gtjn30cw7vdueqnyj06xjqxtmksahdrlg",
            categories: [.newzealand, .news]
        ),
        FeaturedAuthor(
            name: "Kris Sowersby",
            npub: "npub1t6n8u5sa80m6sx53m7uge6afktek4me982wvclr3xe5tfeyg34fslkxqcz",
            categories: [.art, .newzealand]
        )
    ]
}
