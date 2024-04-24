extension DiscoverTab {
    enum FeaturedAuthorCategory: CaseIterable {
        case all
        case new // swiftlint:disable:this identifier_name
        case journalists
        case tech
        case art // swiftlint:disable:this identifier_name
        case environment
        case sports
        case music

        var text: String {
            switch self {
            case .all: "All"
            case .new: "New"
            case .journalists: "Journalists"
            case .tech: "Tech"
            case .art: "Art"
            case .environment: "Environment"
            case .sports: "Sports"
            case .music: "Music"
            }
        }

        var npubs: [String] {
            switch self {
            case .all:
                [
                    "npub1asuq0pxedwfagpqkdf4lrfmcyfaffgptmayel9947j8krad3x58srs20ap",
                    "npub1d9nndmy3lx6f00cysrmn2v9t6hz280uwycw0kgcfdhvg99azry8sududfv",
                    "npub1grz7afdguc67jkjly6fu0xmw0r386t8mtxafutu9u34dy207nt9ql335cv",
                    "npub1yxzkmtuyctjw2pffp6e9uvyrkp29hrqra2tm3xp3z9707z06muxsg75qvv",
                    "npub1d7ggne0xsy8e2999q8cyh9zxda688axm07cwncufjeku0nahvfgsyz6qzr",
                    "npub17a49ajzjlwjv4znh85jcfgmk7qq5ck8m5advx66rudz8g0v034kss2hnk3",
                    "npub1l9kr6ajfwp6vfjp60vuzxwqwwlw884dff98a9cznujs520shsf9s35xfwh",
                    "npub1uh8e4y97tvs5zhsq6srr43qy0u66zk8xfy08xcrhef2803sdfcrslq62el",
                    "npub1aylzctp5p20yc842qfpu2w9j8q0kpqcfx8q3p42ugnp3t8uxg3xq3k8nn0"
                ]
            case .new:
                [
                    "npub1asuq0pxedwfagpqkdf4lrfmcyfaffgptmayel9947j8krad3x58srs20ap"
                ]
            case .journalists:
                [
                    "npub1d9nndmy3lx6f00cysrmn2v9t6hz280uwycw0kgcfdhvg99azry8sududfv",
                    "npub1grz7afdguc67jkjly6fu0xmw0r386t8mtxafutu9u34dy207nt9ql335cv"
                ]
            case .tech:
                [
                    "npub1d9nndmy3lx6f00cysrmn2v9t6hz280uwycw0kgcfdhvg99azry8sududfv",
                    "npub1grz7afdguc67jkjly6fu0xmw0r386t8mtxafutu9u34dy207nt9ql335cv",
                    "npub1yxzkmtuyctjw2pffp6e9uvyrkp29hrqra2tm3xp3z9707z06muxsg75qvv"
                ]
            case .art:
                [
                    "npub1d7ggne0xsy8e2999q8cyh9zxda688axm07cwncufjeku0nahvfgsyz6qzr",
                    "npub17a49ajzjlwjv4znh85jcfgmk7qq5ck8m5advx66rudz8g0v034kss2hnk3",
                    "npub1l9kr6ajfwp6vfjp60vuzxwqwwlw884dff98a9cznujs520shsf9s35xfwh"
                ]
            case .environment:
                [
                    "npub1uh8e4y97tvs5zhsq6srr43qy0u66zk8xfy08xcrhef2803sdfcrslq62el"
                ]
            case .sports:
                [
                    "npub1aylzctp5p20yc842qfpu2w9j8q0kpqcfx8q3p42ugnp3t8uxg3xq3k8nn0"
                ]
            case .music:
                [
                    "npub1asuq0pxedwfagpqkdf4lrfmcyfaffgptmayel9947j8krad3x58srs20ap"
                ]
            }
        }
    }
}
