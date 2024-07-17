import XCTest

/// Tests for `NostrIdentifier`.
class NostrIdentifierTests: XCTestCase {
    /// Example taken from [NIP-19](https://github.com/nostr-protocol/nips/blob/master/19.md)
    func test_npub() throws {
        let npub = "npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6"
        let identifier = try NostrIdentifier.decode(bech32String: npub)
        switch identifier {
        case .npub(let publicKey):
            XCTAssertEqual(publicKey, "3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459d")
        default:
            XCTFail("Expected to get a npub")
        }
    }

    /// Example taken from note1r3r97suudrm3ac5frglug4rywtewa87del40un5y4jv8nncpym6qrlgckt which links to
    /// note13frsueju0qs6dqgr4y6zf6h729w5tjeve9ws6aqm94qhtkhmvwqqu3c2sh
    func test_note() throws {
        let note = "note13frsueju0qs6dqgr4y6zf6h729w5tjeve9ws6aqm94qhtkhmvwqqu3c2sh"
        let identifier = try NostrIdentifier.decode(bech32String: note)
        switch identifier {
        case .note(let eventID):
            XCTAssertEqual(eventID, "8a470e665c7821a68103a93424eafe515d45cb2cc95d0d741b2d4175dafb6380")
        default:
            XCTFail("Expected to get a note")
        }
    }

    /// Example taken from [NIP-19](https://github.com/nostr-protocol/nips/blob/master/19.md)
    func test_nprofile() throws {
        // swiftlint:disable:next line_length
        let nprofile = "nprofile1qqsrhuxx8l9ex335q7he0f09aej04zpazpl0ne2cgukyawd24mayt8gpp4mhxue69uhhytnc9e3k7mgpz4mhxue69uhkg6nzv9ejuumpv34kytnrdaksjlyr9p"

        let identifier = try NostrIdentifier.decode(bech32String: nprofile)
        switch identifier {
        case .nprofile(let publicKey, let relays):
            XCTAssertEqual(publicKey, "3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459d")
            XCTAssertEqual(relays.count, 2)
            let firstRelay = try XCTUnwrap(relays.first)
            XCTAssertEqual(firstRelay, "wss://r.x.com")
            let secondRelay = try XCTUnwrap(relays.last)
            XCTAssertEqual(secondRelay, "wss://djbas.sadkb.com")
        default:
            XCTFail("Expected to get a nprofile")
        }
    }

    /// Example taken from [#1234](https://github.com/planetary-social/nos/issues/1234) which points to
    /// note1ar8gnwj6ugxyq6w9aqur74s2sn4dttk6zx0d25p34fsg476kqrksmkqqnr
    func test_nprofile_with_9_relays() throws {
        // swiftlint:disable:next line_length
        let nprofile = "nprofile1qyvhwumn8ghj7un9d3shjtnndehhyapwwdhkx6tpdshszrnhwden5te0dehhxtnvdakz7qghwaehxw309aex2mrp0yhxummnw3ezucnpdejz7qg4waehxw309aex2mrp0yhxgctdw4eju6t09uq3xamnwvaz7tm0venxx6rpd9hzuur4vghszxnhwden5te0wfjkccte9eeks6t5vehhycm99ehkuef0qy08wumn8ghj7mn0wd68yttsw43zuam9d3kx7unyv4ezumn9wshszxrhwden5te0wfjkccte9e3h2unjv4h8gtnx095j7qgawaehxw309ahx7um5wghx6at5d9h8jampd3kx2apwvdhk6tcqyqe4dhnpkwty0ycuazepgzet4wphuzqscrh4zka7jt0qyjqypw9a60jrgzx"

        let identifier = try NostrIdentifier.decode(bech32String: nprofile)
        switch identifier {
        case .nprofile(let publicKey, let relays):
            XCTAssertEqual(publicKey, "3356de61b39647931ce8b2140b2bab837e0810c0ef515bbe92de0248040b8bdd")
            XCTAssertEqual(relays.count, 9)
            let firstRelay = try XCTUnwrap(relays.first)
            XCTAssertEqual(firstRelay, "wss://relay.snort.social/")
        default:
            XCTFail("Expected to get a nprofile")
        }
    }

    /// Example taken from [#1231](https://github.com/planetary-social/nos/issues/1231) which points to
    /// note1qq7am022xm40yrj9k4agcfqwre4lflsq6mytky0suxunrk7ldf5sjwth8x
    func test_nevent() throws {
        // swiftlint:disable:next line_length
        let nevent = "nevent1qyt8wumn8ghj7un9d3shjtnddaehgu3wwp6kytcpz9mhxue69uhkummnw3ezumrpdejz7qg4waehxw309aex2mrp0yhxgctdw4eju6t09uq3wamnwvaz7tmjv4kxz7fwwpexjmtpdshxuet59uq32amnwvaz7tmwdaehgu3wdau8gu3wv3jhvtcpr4mhxue69uhkummnw3ezucnfw33k76twv4ezuum0vd5kzmp0qyv8wumn8ghj7mn0wd68ytnxd46zuamf0ghxy6t69uq3jamnwvaz7tmjv4kxz7fwwdhx7un59eek7cmfv9kz7qghwaehxw309aex2mrp0yhxummnw3ezucnpdejz7qg3waehxw309ahx7um5wgh8w6twv5hsqg9p8569xea0fgnv0zuqnt3wsk5mu9j6xal7ten6332pg9r5h8g32gl7wn5w"

        let identifier = try NostrIdentifier.decode(bech32String: nevent)
        switch identifier {
        case .nevent(let eventID, let relays, let publicKey, let kind):
            XCTAssertEqual(eventID, "a13d345367af4a26c78b809ae2e85a9be165a377fe5e67a8c54141474b9d1152")

            XCTAssertEqual(relays.count, 10)
            let firstRelay = try XCTUnwrap(relays.first)
            XCTAssertEqual(firstRelay, "wss://relay.mostr.pub/")
            let secondRelay = try XCTUnwrap(relays.last)
            XCTAssertEqual(secondRelay, "wss://nostr.wine/")

            XCTAssertNil(publicKey)
            XCTAssertNil(kind)
        default:
            XCTFail("Expected to get a nevent")
        }
    }

    /// Example taken from note1ypppzcue3svj2p0l80vp4lf52j3xmykn8yzjdv3gnq2sm4ljp5qqrqp9hd
    func test_nevent_with_7_relays() throws {
        // swiftlint:disable:next line_length
        let nevent = "nevent1qydhwumn8ghj7emvv4shxmmwv96x7u3wv3jhvtmjv4kxz7gprpmhxue69uhkummnv3exjan99eshqup0wfjkccteqyt8wumn8ghj7un9d3shjtnddaehgu3wwp6kytcpzamhxue69uhhyetvv9ujuurjd9kkzmpwdejhgtcpr9mhxue69uhhyetvv9ujuumwdae8gtnnda3kjctv9uq32amnwvaz7tmjv4kxz7fwv3sk6atn9e5k7tcprdmhxue69uhkummnw3e8gctvdvhxummnw3erztnrdakj7qpq38c7tac2uhqvqvxnv5d9mrq4km46pf232v9at473watm6597vucq4rru2q"

        let identifier = try NostrIdentifier.decode(bech32String: nevent)
        switch identifier {
        case .nevent(let eventID, let relays, let publicKey, let kind):
            XCTAssertEqual(eventID, "89f1e5f70ae5c0c030d3651a5d8c15b6eba0a551530bd5d7d17757bd50be6730")

            XCTAssertEqual(relays.count, 7)
            let firstRelay = try XCTUnwrap(relays.first)
            XCTAssertEqual(firstRelay, "wss://gleasonator.dev/relay")
            let secondRelay = try XCTUnwrap(relays.last)
            XCTAssertEqual(secondRelay, "wss://nostrtalk.nostr1.com/")

            XCTAssertNil(publicKey)
            XCTAssertNil(kind)
        default:
            XCTFail("Expected to get a nevent")
        }
    }

    /// Example taken from note16fddcyxfldwre2zywr96fnkmk7n3rtf4ehntdwy8ltyqgfntwfnq0dm347
    func test_nevent_with_10_relays() throws {
        // swiftlint:disable:next line_length
        let nevent = "nevent1qy2hwumn8ghj7un9d3shjtnyv9kh2uewd9hj7qgewaehxw309aex2mrp0yh8xmn0wf6zuum0vd5kzmp0qyd8wumn8ghj7urewfsk66ty9enxjct5dfskvtnrdakj7qgwwaehxw309ahx7uewd3hkctcprdmhxue69uhkummnw3e8gctvdvhxummnw3erztnrdakj7qgkwaehxw309ajkgetw9ehx7um5wghxcctwvshszymhwden5te0wp6hyurvv4cxzeewv4ej7qghwaehxw309aex2mrp0yhxummnw3ezucnpdejz7qghwaehxw309aex2mrp0yh8qunfd4skctnwv46z7qgnwaehxw309aex2mrp0yhxvdm69e5k7tcqypr4d8t87evy6gka9xce8asxfr2kztrplttejhxzzamhkptceghxzxkjapf"

        let identifier = try NostrIdentifier.decode(bech32String: nevent)
        switch identifier {
        case .nevent(let eventID, let relays, let publicKey, let kind):
            XCTAssertEqual(eventID, "47569d67f6584d22dd29b193f60648d5612c61fad7995cc217777b0578ca2e61")

            XCTAssertEqual(relays.count, 10)
            let firstRelay = try XCTUnwrap(relays.first)
            XCTAssertEqual(firstRelay, "wss://relay.damus.io/")

            XCTAssertNil(publicKey)
            XCTAssertNil(kind)
        default:
            XCTFail("Expected to get a nevent")
        }
    }

    /// Example taken from note12h0l6emckxgdfjnl3pfvyss4gp03yta7k0n9uwghywksksyfr9ws8q6war
    func test_naddr_with_one_relay() throws {
        // swiftlint:disable:next line_length
        let naddr = "naddr1qqjrsdf4xs6nvdrz95unsery956rswrx95unxvee94skvvp5xymkgwfcx9snyqg3waehxw309ahx7um5wgh8w6twv5hsygx0gknt5ymr44ldyyaq0rn3p5jpzkh8y8ymg773a06ytr4wldxz55psgqqqwense4rlem"

        let identifier = try NostrIdentifier.decode(bech32String: naddr)
        switch identifier {
        case .naddr(let replaceableID, let relays, let authorID, let kind):
            XCTAssertEqual(replaceableID, "8554564b-98dd-488f-9339-af0417d981a2")
            XCTAssertEqual(relays.count, 1)
            let firstRelay = try XCTUnwrap(relays.first)
            XCTAssertEqual(firstRelay, "wss://nostr.wine/")
            XCTAssertEqual(authorID, "cf45a6ba1363ad7ed213a078e710d24115ae721c9b47bd1ebf4458eaefb4c2a5")
            XCTAssertEqual(kind, 30_311)
        default:
            XCTFail("Expected to get a naddr")
        }
    }

    /// Example taken from note1xsems9u6xqfxl3hd3z4u4yr67vvf3g6w5l5vxwl8vqwcp0kgm2hsg3zf2w
    func test_naddr_with_9_relays() throws {
        // swiftlint:disable:next line_length
        let naddr = "naddr1qvzqqqrujgpzp75cf0tahv5z7plpdeaws7ex52nmnwgtwfr2g3m37r844evqrr6jqyghwumn8ghj7vf5xqhxvdm69e5k7tcpzdmhxue69uhhqatjwpkx2urpvuhx2ue0qythwumn8ghj7un9d3shjtnswf5k6ctv9ehx2ap0qy2hwumn8ghj7un9d3shjtnyv9kh2uewd9hj7qg6waehxw309ac8junpd45kgtnxd9shg6npvchxxmmd9uq3xamnwvaz7tmjv4kxz7fwvcmh5tnfduhsz9thwden5te0wfjkccte9ejhs6t59ec82c30qyf8wumn8ghj7un9d3shjtn5dahkcue0qy88wumn8ghj7mn0wvhxcmmv9uqpqvenx56njvpnxqcrsdf4xqcrwdqufrevn"

        let identifier = try NostrIdentifier.decode(bech32String: naddr)
        switch identifier {
        case .naddr(let replaceableID, let relays, let authorID, let kind):
            XCTAssertEqual(replaceableID, "3355903008550074")
            XCTAssertEqual(relays.count, 9)
            let firstRelay = try XCTUnwrap(relays.first)
            XCTAssertEqual(firstRelay, "wss://140.f7z.io/")
            XCTAssertEqual(authorID, "fa984bd7dbb282f07e16e7ae87b26a2a7b9b90b7246a44771f0cf5ae58018f52")
            XCTAssertEqual(kind, 31_890)
        default:
            XCTFail("Expected to get a naddr")
        }
    }

    /// Example taken from note1tq4d6t3ekq2r52z2t2hqkusjcecv4qmaqjyddhzrzn3whphp69wqm833es
    func test_naddr_with_kind_30023() throws {
        // swiftlint:disable:next line_length
        let naddr = "naddr1qqyrsctxxpjnqdpnqyghwumn8ghj7enfv96x5ctx9e3k7mgzyqalp33lewf5vdq847t6te0wvnags0gs0mu72kz8938tn24wlfze6qcyqqq823c4p5dms"

        let identifier = try NostrIdentifier.decode(bech32String: naddr)
        switch identifier {
        case .naddr(let replaceableID, let relays, let authorID, let kind):
            XCTAssertEqual(replaceableID, "8af0e043")
            XCTAssertEqual(relays.count, 1)
            let firstRelay = try XCTUnwrap(relays.first)
            XCTAssertEqual(firstRelay, "wss://fiatjaf.com")
            XCTAssertEqual(authorID, "3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459d")
            XCTAssertEqual(kind, 30_023)
        default:
            XCTFail("Expected to get a naddr")
        }
    }

    /// Example taken from note1tyt3a7tqxhgvvve87jzxpsndguw6vq29qfuenau40kartujlrppq5zmncg
    func test_naddr_with_no_relays() throws {
        // swiftlint:disable:next line_length
        let naddr = "naddr1qvzqqqr4gupzqqn84g7e954y0xkkhnxudlnk2uphm645kaagh08axe3mpmh3j66cqq24g3mwgffxswfdvgck5un32d9z6sne2aghskj3r5v"

        let identifier = try NostrIdentifier.decode(bech32String: naddr)
        switch identifier {
        case .naddr(let replaceableID, let relays, let authorID, let kind):
            XCTAssertEqual(replaceableID, "TGnBRh9-b1jrqSJ-ByWQx")
            XCTAssertEqual(relays.count, 0)
            XCTAssertEqual(authorID, "0267aa3d92d2a479ad6bccdc6fe7657037deab4b77a8bbcfd3663b0eef196b58")
            XCTAssertEqual(kind, 30_023)
        default:
            XCTFail("Expected to get a naddr")
        }
    }
}
