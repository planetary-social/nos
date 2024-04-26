// swiftlint:disable file_length
import secp256k1
import Foundation
import CoreData
import RegexBuilder
import SwiftUI
import Logger
import Dependencies

enum EventError: Error {
	case utf8Encoding
	case unrecognizedKind
    case missingAuthor
    case invalidETag([String])
    case invalidSignature(Event)
    case expiredEvent

    var description: String? {
        switch self {
        case .unrecognizedKind:
            return "Unrecognized event kind"
        case .missingAuthor:
            return "Could not parse author on event"
        case .invalidETag(let strings):
            return "Invalid e tag \(strings.joined(separator: ","))"
        case .invalidSignature(let event):
            return "Invalid signature on event: \(String(describing: event.identifier))"
        case .expiredEvent:
            return "This event has expired"
        default:
            return "An unkown error occurred."
        }
	}
}

public enum EventKind: Int64, CaseIterable, Hashable {
	case metaData = 0
	case text = 1
	case contactList = 3
	case directMessage = 4
	case delete = 5
    case repost = 6
	case like = 7
    case seal = 13
    case directMessageRumor = 14
    case channelMessage = 42
    case giftWrap = 1059
    case label = 1985
    case report = 1984
    case mute = 10_000
    case longFormContent = 30_023
    case notificationServiceRegistration = 6666
    case auth = 27_235
}

// swiftlint:disable type_body_length
@objc(Event)
@Observable
public class Event: NosManagedObject, VerifiableEvent {
    @Dependency(\.currentUser) @ObservationIgnored private var currentUser

    var pubKey: String { author?.hexadecimalPublicKey ?? "" }
    static var replyNoteReferences = "kind = 1 AND ANY eventReferences.referencedEvent.identifier == %@ " +
        "AND author.muted = false"
    public static var discoverKinds = [EventKind.text, EventKind.longFormContent]

    @nonobjc public class func allEventsRequest() -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.createdAt, ascending: true)]
        return fetchRequest
    }
    
    /// The userId mapped to an array of strings witn information of the user
    static let discoverTabUserIdToInfo: [String: [String]] = [
        "npub1sg6plzptd64u62a878hep2kev88swjh3tw00gjsfl8f237lmu63q0uf63m": ["Jack Dorsey"],
        "npub176ar97pxz4t0t5twdv8psw0xa45d207elwauu5p93an0rfs709js4600cg": ["arjwright"],
        "npub1nstrcu63lzpjkz94djajuz2evrgu2psd66cwgc0gz0c0qazezx0q9urg5l": ["nostrica"],
        "npub14ps5krdd2wezq4kytmzv3t5rt6p4hl5tx6ecqfdxt5y0kchm5rtsva57gc": ["Martin"],
        "npub1uaajg6r8hfgh9c3vpzm2m5w8mcgynh5e0tf0um4q5dfpx8u6p6dqmj87z6": ["Chardot"],
        "npub1uucu5snurqze6enrdh06am432qftctdnehf8h8jv4hjs27nwstkshxatty": ["boreq"],
        "npub1wmr34t36fy03m8hvgl96zl3znndyzyaqhwmwdtshwmtkg03fetaqhjg240": ["rabble"],
        "npub16zsllwrkrwt5emz2805vhjewj6nsjrw0ge0latyrn2jv5gxf5k0q5l92l7": ["Matt Lorentz"],
        "npub1lur3ft9rk43fmjd2skwefz0jxlhfj0nyz3zjfkxwe3y8xlf5r6nquat0xg": ["Shaina Dane"],
        "npub1ey39gym4zlppcsvquqhv0cujnsn6uwuu9z9f4sxkzp5vjy8gfa9sprdq23": ["Linda"],
        "npub1yl8jc6znttslcpj3p6p8vuq98awu6w0xh4lqtu0lkjr772kpx4ysfqvz34": ["Josh Brown"],
        "npub1nk5d3lqqckfrju9rmvuqhx5swe60e68dgeulgswpv4v9jdnczf7q0eslc0": ["Causes"],
        "npub1pu3vqm4vzqpxsnhuc684dp2qaq6z69sf65yte4p39spcucv5lzmqswtfch": ["Nos.Social"],
        "npub1xdtducdnjerex88gkg2qk2atsdlqsyxqaag4h05jmcpyspqt30wscmntxy": ["brugeman"],
        "npub1sn0wdenkukak0d9dfczzeacvhkrgz92ak56egt7vdgzn8pv2wfqqhrjdv9": ["Edward Snowden"],
        "npub1veeqt66jt2j209y9nv4a90w3dej074lavqygq5q0c57dharkgw0qk738wt": ["S3x_jay"],
        "npub1f594agr5xkjd9vgxqgdw0el56y55satlh4ey4mck6trfmxhf4gdsh9npnz": ["Bobi"],
        "npub1ctsq6nmn5af0evwrlka32kqc7tuhkwzmxlmu6lxt5qw2r6wfnuaqmcad65": ["Julien"],
        "npub10ft5tkcwknwqkspx9cxhxy2yvyqzmavjku7g37n2kk9ja9yd5rwshhz4z3": ["Joi Ito"],
        "npub1dcl4zejwr8sg9h6jzl75fy4mj6g8gpdqkfczseca6lef0d5gvzxqvux5ey": ["Adam Ritter"],
        "npub1gk6ufj53zcc07dt8vrnwwslr3zqs2z398808z9gaw0pl2znmacrqp5y8se": ["Andressa Muntro"],
        "npub188dexxxmyqhj2r9yte0eq08kfrxtgdmer6gz0ljnzq06edc5fttsjtt409": ["Mary Yar"],
        "npub1a32cg8ntvpcq0gqk00t73kzywptxjvm2aatysk6g7nfc750976xsm2ea5z": ["Johannes Ernst"],
        "npub17nd4yu9anyd3004pumgrtazaacujjxwzj36thtqsxskjy0r5urgqf6950x": ["isoabellaart"],
        "npub1rkqw2kyduqgdzdax03ptqdcht90475gww0jzelzg7vd6ayvyf4vsl2jtk0": ["bannana art"],
        "npub1chuth0ru5mq5pjeq6magew3kse4d5m7wgzqk3tnz0kgqwu3vt6ls5hq3gd": ["chut"],
        "npub1ke0hjv9nx5cy4kz3yuw9kwrhey72cphh8cehfnrh2gjlm8dq7ujsuwt0pu": ["LucioMint"],
        "npub1a406tcmltkud34kmqkevkpykp384czamffw2245a9v5uc2z22l2q55gxd2": ["tina"],
        "npub1matmfxr293jejewrm72u50l2x5e6ypasn0ev2kns6srv05zfzf8s0z6fsr": ["Jon Pincus"],
        "npub1ftpy6thgy2354xypal6jd0m37wtsgsvcxljvzje5vskc9cg3a5usexrrtq": ["Raúl Piracés"],
        "npub1l9kr6ajfwp6vfjp60vuzxwqwwlw884dff98a9cznujs520shsf9s35xfwh": ["Karine"],
        "npub1rfdkj37rhymcrr5jk9jjaae5c3yj8l24jtr8a27q0chh2y2aq42snhh53u": ["eolaí"],
        "npub1uch5rxswzes8h9hlzrktqqjf4a75k6w86ys7fvzpxrrpejvccvhq4sl7fj": ["muneomi"],
        "npub1p458ltjfrxmcymk4j3plsmsksaqsf62cggdqvhv9cphk0wdglzts80t20a": ["Adhhafi"],
        "npub19mduaf5569jx9xz555jcx3v06mvktvtpu0zgk47n4lcpjsz43zzqhj6vzk": ["Nostr Report"],
        "npub15c7vxfun6g3450qpvx4pt68mf90t3fc08rd3nc5ldhfz6af60m5qftlahr": ["Matt Cengia"],
        "npub1erhg86xl307d46pla66aycr6sjpy9esnrffysr98l5pjvt2fdgeq8wru26": ["farfallica"],
        "npub12h5xc0usentknjnldce6a80tq0m475u6ucgwhlk2zsfqax3x94fsmx0rvt": ["Weisheiten"],
        "npub166l9t9ckan9yh6j8pku0stszkekt0s8uhqwvddz4qr92r9w0wxcs59u7c3": ["taylan"],
        "npub1pmwz736ys3mfhjdld4r36xqwfc5qkz7dwxdkmfu3qqd7kucvludsrm4nu6": ["lizsweig"],
        "npub1q50ex3alz6jz9p9pc6yler38wru0sf6ge7kjsfks08ewj90jumfq0euvf3": ["Urzeitshop"],
        "npub1kwdcaq7e9pluu0f9s7rdlj7sqscf37ty6rv7fl92k4nqcr3ezfts8enny4": ["The Free Quaker"],
        "npub1qcxmjzt90y8g3kwych8r8x4wf0s6chm4z27ftgglxqcr4e7mhf5svwxq0z": ["Domingos Faria"],
        "npub105em547c5m5gdxslr4fp2f29jav54sxml6cpk6gda7xyvxuzmv6s84a642": ["Travel Telly"],
        "npub1mhrdsyurcmnva5783cuwmvp2k6kqc7er47lh56z5zr48ha5fhgesf5028h": ["BeatingUpwind"],
        "npub1zwulrffp23wle3tl25dt0jr2q376k0k8vhe9xzjl5jnxnag5tc2sr2hjds": ["Love of Nature"],
        "npub1sur5gd3mrfvcd4nh8dtsdh0ztrqrnaknff0lcfcfz5pn56n8eqkqv9sm0l": ["Animals"],
        "npub1tvw3h5xqnuc2aq5zelxp3dy58sz7x9u8e6enkxywmrz70cg2j2zqjes44n": ["Tech Priest"],
        "npub1zumnu05rrr7fg608gereh7a2v0prtea4dc9m4wzgkxut965ru8qqf4j3xg": ["Nostalgia"],
        "npub19fwwstv5dg8qsmuj9rmgf98nt9lfz5gvv67jqx6y9jtgekpcz5pqpgulzp": ["Pro Publica"],
        "npub12zwrghc9rr9pggd6nun2nzkxkzm03p93sa8dnssryr75z9vrz0jqvyuequ": ["Ars Technica"],
        "npub1mdpmt8tyugp2n45yasutja0hqhd2r3ue7cx6qdtcaed7yfu7j05sqpg3tt": ["J.L. Westover"],
        "npub144g96mhz52cetf9xfhajtk5qxzh9689mhge73g8h8tz6hjf5eeuqvhljnp": ["War and Peas"],
        "npub18gz3mp59zawrfs5y50ej9m9ja7sty69lccmwemcxjz8qyfgquegq59hsf0": ["Flipboard"],
        "npub1dp2pmvv7gzp6dfmhpwn88emdtr55t7nrmplhmcj80cpu053parwsv25lx7": ["Lisa Melton"],
        "npub1su03jcgka9t76zqsdky4t0lt5x48ml5qwsfkqs5ztrrejk8qq7yq0eaazr": ["We Built This City"],
        "npub19pcmh42v2yjdh5y8e5p9y2kpfhzk894xgk4yqr9ktczrn5jr776smqmf48": ["Anthony Dean"],
        "npub1mljsj4htqa6hzfzy85476777tc07nxtvd6gpjl8h2d5fp0usw02se6r47k": ["Charles Johnson"],
        "npub1f4xayf53h3kvrzz9824ymsq5acl6gw09jrjczpxt50y6j0ahakhqkfx76m": ["Taras Grescoe"],
        "npub1d7ggne0xsy8e2999q8cyh9zxda688axm07cwncufjeku0nahvfgsyz6qzr": ["Matt Blaze"],
        "npub1l93rswuh9fewt2ks4p9pu93llzadglx0znp5uwwvhj6ywuetalwqa7mzuz": ["Matt Hodges"],
        "npub1cva9dqhte2zplzwsn2f23g0p2c67xvue4m9m25qsmwfjclqmq8lspfghm6": ["David AUgust"],
        "npub133yzwsqfgvsuxd4clvkgupshzhjn52v837dlud6gjk4tu2c7grqq3sxavt": ["Maddest Max"],
        "npub18xhl0f2tsessutc3x5d8e7jda7kfuzgutkktd532sjttvz6fnxls337cq3": ["Keith Whyte"],
        "npub1qlxf6s2pl2djx3x4j7ccz0mucqakvdcavanfud6xjhkrr7g3vdqsh90zvf": ["Magess"],
        "npub1tqkzr6ndytnufcrrztme4d0m2ql77988sz7w8euzn3acntzphlzqa08tap": ["James Vasile"],
        "npub1mkpyfxkpnvdautfwd6jq2kantpx54kam7hlzq0nn0vu5vavtutqsxvyr60": ["Max Hertzberg"],
        "npub1mjcn8x74pdvg4swnfxhn0ljkjx29dgkszknctlmuu2kfzg034amqycg03p": ["Robin Berjon"],
        "npub1me4dmfx38938e68eeuz77f78e5w7nz2nv0jlxqmx0amphmp3sutq6s0ues": ["Christian Selig"],
        "npub1hhun74sfzza54h7ryv2zyyl5p4qlwsm4urtp9ywq6fyvg39ax3fq78ypr9": ["John Philpin"],
        "npub1r8mgrcp5ap7dhn6rgmlx3jswv9jnuv9cxvdga38x896xj3arnm2stjjz5n": ["vruz"],
        "npub1gh4q2xa2n2ar7nzgpydfykh733xdynuslz3heardn99auzkv2zcstqlqd5": ["Brian Cantrill"],
        "npub16xfqjdlukvd5y92fm7qwyqerluqkhcl3xxgumty5wezk9zpud4gswxe0sv": ["Shoq"],
        "npub1vgp7udg8u8u4pep06a7y30l3s87kt6quzyqu7vaf82el6rnm2cmqwgtcn8": ["Christine Lemmber Webber"],
        "npub1ztkzuu8cl5rfeah0k26yxvylvchkg9xzmw7l5jvekkc9263sjnrs9258pt": ["ItsGoingDown"],
        "npub1ly9r02zq97hysrxncxhlexu9rjgf2mre0k28tcn98n9k4s40m2lql36jpu": ["Matt K"],
        "npub1txfduepxzvrg6q0hwkh2hfwsawjm9cqtyqa26v0takgggxggzj6sz5rxdr": ["Calvin Bell"],
        "npub1wyr8y0rdeaqvwdvqtkm8pzyrrqsy9c3pc5pa27xxl5u0twyt602stny2wn": ["Galen"],
        "npub1q3erhydshlxz7xgmhcdvy2euy4ah2tvnt5pk2wgefyrrv8agh5wq4edfpk": ["Alan McConchie"],
        "npub18tyt95ke27wqdhppnr677ahkar86etv840rqlfyfhkhuwv30zmesawwfrd": ["Blim Antogonist"],
        "npub17sn2jzhqzccn9j7h6vhywec2zr6lzw5p2d5z7lnplsxwqvrs4duqv6jgfe": ["Georage Takei"],
        "npub1uhzmveltn3t8klxm5ltz5l8hw0cp0t6ss9h5whma825hfzgqrfysskezz4": ["Neil Gaiman"],
        "npub1dzkq7f7q23fh0mrw03wwd23ddmu258k6m34gctl6ark6qlex4l7qskqcce": ["Robert Reich"],
        "npub1hhhum4hrc5alsfgl4u248nqduf4lsmvca5kew4hmaezuzqctgx9sa6ppg2": ["Jan Bohemeramann"],
        "npub1d9nndmy3lx6f00cysrmn2v9t6hz280uwycw0kgcfdhvg99azry8sududfv": ["Taylor Lorenz"],
        "npub1z04g44eclq892f8zn7xvw83cyzfcmw3aqaxv82e6lhpwkfaypaws8aw6eg": ["Stux"],
        "npub1m2tcxd9nhm4l5uk775qs4ggv4yj70yw49zus29nrk9sd2zk7xmvqkcgvf2": ["Popehat"],
        "npub18n3yh0g4u9k0jlp2ux38cyatg7300s40z4g9vsvg7at6lneau5usalwg29": ["Der Postillon"],
        "npub1dkpwe7v5tnq59q5f57ay3qxcfknm7r4yr765tl8kttxr8judnrxs790xl8": ["Greta Thunberg"],
        "npub18mmgvu4457x8yrsr3djhhnfp8uhp5swj6fed6jyrd3cpu0vwfcfs3mwg7n": ["European Commission"],
        "npub17fjpccfwjdsklnauh2x6cs0rkqmppdpjjgh5q0963q4yjn9qnkxqm9gh0n": ["Mark Ruffalo"],
        "npub1y8av7a5337erepxphjf50c9p4w5ghu6zu56fjqklpw0n06d7wvgqwh5cy0": ["Tor Project"],
        "npub1hjugp75htg9zx2xhkk0h2zen47yfx9de3mkade4g4q7m9tn56atqwhq06v": ["Digital Courage"],
        "npub1dt25tmqsqh6xp9v6ewcgwm4q3cp93n9atenac69v7h2kw0fa8l0qx2z3ug": ["Stray Cat Observer"],
        "npub1yegarmnp85dj05k7292mhm0m4jhv7yr7znq2tncsnthtshsn5xns283nns": ["JF Martin"],
        "npub1ylccvgzdlan2vyh4snx9u8kjpk8580tm2ecxmvv72mzem3xevt9qw0z7ks": ["Elon Musk's Jet"],
        "npub1c8jd3qucegcz4qtrztvfj5vhag9c57q23dsvne07yz2l6x2h87ssham228": ["Guido Kühn"],
        "npub1z3mkez22qs9j4nve8dg08m8wxave66yc2q8zrmmxjm9f3pt5wfmqslfm29": ["Yogthos"],
        "npub1ym3ynkrv78fet2l3d83n6vek0lkjcjd6mz93ksx2zuz7jlnh53rsr67jpq": ["Laszlo"],
        "npub1lunaq893u4hmtpvqxpk8hfmtkqmm7ggutdtnc4hyuux2skr4ttcqr827lj": ["Stuart Bowman"],
        "npub1qhldxsy0v533gd64fge20cw9y7mtyevhrelh9nusddqfwyw4euvsrt66cz": ["Andreas Schneider"],
        "npub1nwwtpxvzgjtspmyeuqsxlmk5rum8zgmlcsum8t55dggsaytm0kdqs2etu5": ["Kalou"],
        "npub1c878wu04lfqcl5avfy3p5x83ndpvedaxv0dg7pxthakq3jqdyzcs2n8avm": ["Ben Arc"],
        "npub1xz5g8uqpmg3mqvezjhfnev660m0h476wk3rssra44fn87gwgequqwra02a": ["Lahmienwski Lab"],
        "npub1plx4lff553p6kryg2vkrf47h82lcsvjespfdcv5zmzmn03429psst9hnwk": ["Dylan"],
        "npub1cl3098w2krckyfyyzcnnefltuggvj0ke32p3kag88v3wsx5j4y8q5e69y2": ["Leaa"],
        "npub19sjwrt6hr76velk28xqkf8qmp8rftnvrky5hp84nksw84559fzvsq7ccqn": ["MrsNancyJ"],
        "npub1995y964wmxl94crx3ksfley24szjr390skdd237ex9z7ttp5c9lqld8vtf": ["franny"],
        "npub14u2x75trff0mp279jtau90k59nm5quqfjq6y5an23xvlu40w68rq40ewrz": ["Kathrin"],
        "npub1rjc54ve4sahunm7r0kpchg58eut7ttwvevst7m2fl8dfd9w4y33q0w0qw2": ["Hes"],
        "npub1wqfzz2p880wq0tumuae9lfwyhs8uz35xd0kr34zrvrwyh3kvrzuskcqsyn": ["MichaelJ"],
        "npub1n0pdxnwa4q7eg2slm5m2wjrln2hvwsxmyn48juedjr3c85va99yqc5pfp6": ["SimplySarah"],
        "npub1zyfv44hl4kezcn2st6de75ejypfwqk5rfq3vlymgm365e2au0w5spdg837": ["Dr. Monali Desai"],
        "npub1r9lucu40595a3qlycc7whv0524664dm6hp7qmah80psvt7zznyzq9vkmz0": ["lynnrose"],
        "npub1qk003dm7f6tqe3ydykawvqrmnze5n444dwql88qxd6hzxczzgv3syh87jz": ["bettyrose"],
        "npub13mh45wl4u9ur26sxxwcklywgyt640s2dqkn6mvsu55302nwvqymq6xae0f": ["Katrin Theresa"]
    ]
    
    // MARK: - Fetching
    
    @nonobjc public class func allPostsRequest(_ eventKind: EventKind = .text) -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.createdAt, ascending: false)]
        fetchRequest.predicate = NSPredicate(format: "kind = %i", eventKind.rawValue)
        return fetchRequest
    }
    
    @nonobjc public class func emptyDiscoverRequest() -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.createdAt, ascending: false)]
        fetchRequest.fetchLimit = 200
        fetchRequest.predicate = NSPredicate.false
        return fetchRequest
    }
    
    @MainActor @nonobjc class func extendedNetworkPredicate(
        currentUser: CurrentUser,
        featuredAuthors: [String], 
        before: Date
    ) -> NSPredicate {
        guard let currentUser = currentUser.author else {
            return NSPredicate.false
        }
        return NSPredicate(
            format: "kind IN %@ AND eventReferences.@count = 0 AND author.hexadecimalPublicKey IN %@ " +
                "AND NOT author IN %@.follows.destination AND NOT author = %@ AND receivedAt <= %@ AND " +
                "author.muted = false AND deletedOn.@count = 0",
            discoverKinds.map { $0.rawValue },
            featuredAuthors.compactMap {
                PublicKey(npub: $0)?.hex
            },
            currentUser,
            currentUser,
            before as CVarArg
        )
    }
    
    @nonobjc public class func seen(on relay: Relay, before: Date, exceptFrom author: Author?) -> NSPredicate {
        let sharedFormat = "kind IN %@ AND eventReferences.@count = 0 AND %@ IN seenOnRelays AND createdAt <= %@" +
            " AND author.muted = NO"
        if let author {
            return NSPredicate(
                format: "\(sharedFormat) AND NOT author = %@",
                discoverKinds.map { $0.rawValue },
                relay,
                before as CVarArg,
                author
            )
        } else {
            return NSPredicate(
                format: sharedFormat,
                discoverKinds.map { $0.rawValue },
                relay,
                before as CVarArg
            )
        }
    }
    
    @nonobjc public class func allMentionsPredicate(for user: Author) -> NSPredicate {
        guard let publicKey = user.hexadecimalPublicKey, !publicKey.isEmpty else {
            return NSPredicate.false
        }
        
        return NSPredicate(
            format: "kind = %i AND ANY authorReferences.pubkey = %@ AND deletedOn.@count = 0",
            EventKind.text.rawValue,
            publicKey
        )
    }

    @nonobjc public class func unpublishedEventsRequest(for user: Author) -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.createdAt, ascending: false)]
        fetchRequest.predicate = NSPredicate(
            format: "author.hexadecimalPublicKey = %@ AND " +
            "SUBQUERY(shouldBePublishedTo, $relay, TRUEPREDICATE).@count > " +
            "SUBQUERY(publishedTo, $relay, TRUEPREDICATE).@count AND " +
            "deletedOn.@count = 0",
            user.hexadecimalPublicKey ?? ""
        )
        return fetchRequest
    }
    
    @nonobjc public class func allRepliesPredicate(for user: Author) -> NSPredicate {
        NSPredicate(
            format: "kind = 1 AND ANY eventReferences.referencedEvent.author = %@ AND deletedOn.@count = 0", 
            user
        )
    }
    
    /// A request for all events that the given user should receive a notification for.
    /// - Parameters:
    ///   - user: the author you want to view notifications for.
    ///   - since: a date that will be used as a lower bound for the request.
    ///   - limit: a max number of events to fetch.
    /// - Returns: A fetch request for the events described.
    @nonobjc public class func all(
        notifying user: Author, 
        since: Date? = nil, 
        limit: Int? = nil
    ) -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.createdAt, ascending: false)]
        if let limit {
            fetchRequest.fetchLimit = limit
        }
        
        let mentionsPredicate = allMentionsPredicate(for: user)
        let repliesPredicate = allRepliesPredicate(for: user)
        let notSelfPredicate = NSPredicate(format: "author != %@", user)
        let notMuted = NSPredicate(format: "author.muted == 0", user)
        let allNotificationsPredicate = NSCompoundPredicate(
            orPredicateWithSubpredicates: [mentionsPredicate, repliesPredicate]
        )
        var andPredicates = [allNotificationsPredicate, notSelfPredicate, notMuted]
        if let since {
            let sincePredicate = NSPredicate(format: "receivedAt >= %@", since as CVarArg)  
            andPredicates.append(sincePredicate)
        } 
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: andPredicates)
        
        return fetchRequest
    }
    
    @nonobjc public class func lastReceived(for user: Author) -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.createdAt, ascending: false)]
        fetchRequest.predicate = NSPredicate(format: "author != %@", user)
        fetchRequest.fetchLimit = 1
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.receivedAt, ascending: false)]
        return fetchRequest
    }
    
    @nonobjc public class func allReplies(to rootEvent: Event) -> NSFetchRequest<Event> {
        allReplies(toNoteWith: rootEvent.identifier)
    }
        
    @nonobjc public class func allReplies(toNoteWith noteID: String?) -> NSFetchRequest<Event> {
        guard let noteID else {
            return emptyRequest()
        }
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.receivedAt, ascending: false)]
        fetchRequest.predicate = NSPredicate(
            format: replyNoteReferences,
            noteID
        )
        return fetchRequest
    }
    
    @nonobjc public class func expiredRequest() -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.predicate = NSPredicate(format: "expirationDate <= %@", Date.now as CVarArg)
        return fetchRequest
    }
    
    @nonobjc public class func event(by identifier: String) -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.predicate = NSPredicate(format: "identifier = %@", identifier)
        fetchRequest.fetchLimit = 1
        return fetchRequest
    }
    
    @nonobjc public class func hydratedEvent(by identifier: String) -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.predicate = NSPredicate(
            format: "identifier = %@ AND createdAt != nil AND author != nil", identifier
        )
        fetchRequest.fetchLimit = 1
        return fetchRequest
    }
    
    @nonobjc public class func event(by identifier: String, seenOn relay: Relay) -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.predicate = NSPredicate(format: "identifier = %@ AND ANY seenOnRelays = %@", identifier, relay)
        fetchRequest.fetchLimit = 1
        return fetchRequest
    }
    
    @nonobjc public class func homeFeedPredicate(for user: Author, before: Date) -> NSPredicate {
        NSPredicate(
            // swiftlint:disable line_length
            format: "((kind = 1 AND SUBQUERY(eventReferences, $reference, $reference.marker = 'root' OR $reference.marker = 'reply' OR $reference.marker = nil).@count = 0) OR kind = 6 OR kind = 30023) AND (ANY author.followers.source = %@ OR author = %@) AND author.muted = 0 AND createdAt <= %@ AND deletedOn.@count = 0",
            // swiftlint:enable line_length
            user,
            user,
            before as CVarArg
        )
    }
    
    @nonobjc public class func homeFeed(for user: Author, before: Date) -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.createdAt, ascending: false)]
        fetchRequest.predicate = homeFeedPredicate(for: user, before: before)
        return fetchRequest
    }

    @nonobjc public class func likes(noteID: String) -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.createdAt, ascending: false)]
        let noteIsLikedByUserPredicate = NSPredicate(
            // swiftlint:disable line_length
            format: "kind = \(String(EventKind.like.rawValue)) AND SUBQUERY(eventReferences, $reference, $reference.eventId = %@).@count > 0 AND deletedOn.@count = 0",
            // swiftlint:enable line_length
            noteID
        )
        fetchRequest.predicate = noteIsLikedByUserPredicate
        return fetchRequest
    }
    
    @nonobjc public class func reposts(noteID: String) -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.createdAt, ascending: false)]
        let noteIsLikedByUserPredicate = NSPredicate(
            // swiftlint:disable line_length
            format: "kind = \(String(EventKind.repost.rawValue)) AND SUBQUERY(eventReferences, $reference, $reference.eventId = %@).@count > 0 AND deletedOn.@count = 0",
            // swiftlint:enable line_length
            noteID
        )
        fetchRequest.predicate = noteIsLikedByUserPredicate
        return fetchRequest
    }
    
    @nonobjc public class func emptyRequest() -> NSFetchRequest<Event> {
        let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.createdAt, ascending: true)]
        fetchRequest.predicate = NSPredicate.false
        return fetchRequest
    }
    
    @nonobjc public class func deleteAllEvents() -> NSBatchDeleteRequest {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Event")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        return deleteRequest
    }
    
    @nonobjc public class func deleteAllPosts(by author: Author) -> NSBatchDeleteRequest {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Event")
        let kind = EventKind.text.rawValue
        let key = author.hexadecimalPublicKey ?? "notakey"
        fetchRequest.predicate = NSPredicate(format: "kind = %i AND author.hexadecimalPublicKey = %@", kind, key)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        return deleteRequest
    }
    
    class func all(context: NSManagedObjectContext) -> [Event] {
        let allRequest = Event.allPostsRequest()
        
        do {
            let results = try context.fetch(allRequest)
            return results
        } catch let error as NSError {
            print("Failed to fetch events. Error: \(error.description)")
            return []
        }
    }
    
    class func unpublishedEvents(for user: Author, context: NSManagedObjectContext) -> [Event] {
        let allRequest = Event.unpublishedEventsRequest(for: user)
        
        do {
            let results = try context.fetch(allRequest)
            return results
        } catch let error as NSError {
            print("Failed to fetch events. Error: \(error.description)")
            return []
        }
    }
    
    class func find(by identifier: RawEventID, context: NSManagedObjectContext) -> Event? {
        if let existingEvent = try? context.fetch(Event.event(by: identifier)).first {
            return existingEvent
        }

        return nil
    }    
    
    func reportsRequest() -> NSFetchRequest<Event> {
        let request = NSFetchRequest<Event>(entityName: "Event")
        request.predicate = NSPredicate(
            format: "kind = %i AND ANY eventReferences.referencedEvent = %@ AND deletedOn.@count = 0", 
            EventKind.report.rawValue,
            self
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Event.identifier, ascending: true)]
        return request
    }
    
    // MARK: - Creating

    func createIfNecessary(
        jsonEvent: JSONEvent, 
        relay: Relay?, 
        context: NSManagedObjectContext
    ) throws -> Event? {
        // Optimization: check that no record exists before doing any fetching
        guard try context.count(for: Event.hydratedEvent(by: jsonEvent.id)) == 0 else {
            return nil
        }
        
        if let existingEvent = try context.fetch(Event.event(by: jsonEvent.id)).first {
            if existingEvent.isStub {
                try existingEvent.hydrate(from: jsonEvent, relay: relay, in: context)
            }
            return existingEvent
        } else {
            let event = Event(context: context)
            event.identifier = jsonEvent.id
            event.receivedAt = .now
            try event.hydrate(from: jsonEvent, relay: relay, in: context)
            return event
        }
    }
    
    /// Fetches the event with the given ID out of the database, and otherwise creates a stubbed Event.
    /// A stubbed event only has an `identifier` - we know an event with this identifier exists but we don't
    /// have its content or tags yet.
    ///  
    /// - Parameters:
    ///   - id: The hexadecimal Nostr ID of the event.
    /// - Returns: The Event model with the given ID.
    class func findOrCreateStubBy(id: RawEventID, context: NSManagedObjectContext) throws -> Event {
        if let existingEvent = try context.fetch(Event.event(by: id)).first {
            return existingEvent
        } else {
            let event = Event(context: context)
            event.identifier = id
            return event
        }
    }
    
    /// Populates an event stub (with only its ID set) using the data in the given JSON.
    func hydrate(from jsonEvent: JSONEvent, relay: Relay?, in context: NSManagedObjectContext) throws {
        guard isStub else {
            fatalError("Tried to hydrate an event that isn't a stub. This is a programming error")
        }
        
        // Meta data
        createdAt = Date(timeIntervalSince1970: TimeInterval(jsonEvent.createdAt))
        if let createdAt, createdAt > .now {
            self.createdAt = .now
        }
        content = jsonEvent.content
        kind = jsonEvent.kind
        signature = jsonEvent.signature
        sendAttempts = 0
        
        // Tags
        allTags = jsonEvent.tags as NSObject
        for tag in jsonEvent.tags {
            if tag[safe: 0] == "expiration",
                let expirationDateString = tag[safe: 1],
                let expirationDateUnix = TimeInterval(expirationDateString),
                expirationDateUnix != 0 {
                let expirationDate = Date(timeIntervalSince1970: expirationDateUnix)
                self.expirationDate = expirationDate
                if isExpired {
                    throw EventError.expiredEvent
                }
            }
        }
        
        // Author
        guard let newAuthor = try? Author.findOrCreate(by: jsonEvent.pubKey, context: context) else {
            throw EventError.missingAuthor
        }
        
        author = newAuthor
        
        // Relay
        relay.unwrap { markSeen(on: $0) }
        
        guard let eventKind = EventKind(rawValue: kind) else {
            throw EventError.unrecognizedKind
        }
        
        switch eventKind {
        case .contactList:
            hydrateContactList(from: jsonEvent, author: newAuthor, context: context)
            
        case .metaData:
            hydrateMetaData(from: jsonEvent, author: newAuthor, context: context)
            
        case .mute:
            hydrateMuteList(from: jsonEvent, context: context)
        case .repost:
            
            hydrateDefault(from: jsonEvent, context: context)
            parseContent(from: jsonEvent, context: context)
            
        default:
            hydrateDefault(from: jsonEvent, context: context)
        }
    }
    
    func hydrateContactList(from jsonEvent: JSONEvent, author newAuthor: Author, context: NSManagedObjectContext) {
        guard createdAt! > newAuthor.lastUpdatedContactList ?? Date.distantPast else {
            return
        }
        
        newAuthor.lastUpdatedContactList = Date(timeIntervalSince1970: TimeInterval(jsonEvent.createdAt))

        // Put existing follows into a dictionary so we can avoid doing a fetch request to look up each one.
        var originalFollows = [RawAuthorID: Follow]()
        for follow in newAuthor.follows {
            if let pubKey = follow.destination?.hexadecimalPublicKey {
                originalFollows[pubKey] = follow
            }
        }
        
        var newFollows = Set<Follow>()
        for jsonTag in jsonEvent.tags {
            if let followedKey = jsonTag[safe: 1], 
                let existingFollow = originalFollows[followedKey] {
                // We already have a Core Data Follow model for this user
                newFollows.insert(existingFollow)
            } else {
                do {
                    newFollows.insert(try Follow.upsert(by: newAuthor, jsonTag: jsonTag, context: context))
                } catch {
                    print("Error: could not parse Follow from: \(jsonEvent)")
                }
            }
        }
        
        // Did we unfollow someone? If so, remove them from core data
        let removedFollows = Set(originalFollows.values).subtracting(newFollows)
        if !removedFollows.isEmpty {
            print("Removing \(removedFollows.count) follows")
            Follow.deleteFollows(in: removedFollows, context: context)
        }
        
        newAuthor.follows = newFollows
        
        // Get the user's active relays out of the content property
        if let data = jsonEvent.content.data(using: .utf8, allowLossyConversion: false),
            let relayEntries = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers),
            let relays = (relayEntries as? [String: Any])?.keys {
            newAuthor.relays = Set()

            for address in relays {
                if let relay = try? Relay.findOrCreate(by: address, context: context) {
                    newAuthor.add(relay: relay)
                }
            }
        }
    }
    
    func hydrateDefault(from jsonEvent: JSONEvent, context: NSManagedObjectContext) {
        let newEventReferences = NSMutableOrderedSet()
        let newAuthorReferences = NSMutableOrderedSet()
        for jsonTag in jsonEvent.tags {
            if jsonTag.first == "e" {
                // TODO: validdate that the tag looks like an event ref
                do {
                    let eTag = try EventReference(jsonTag: jsonTag, context: context)
                    newEventReferences.add(eTag)
                } catch {
                    print("error parsing e tag: \(error.localizedDescription)")
                }
            } else if jsonTag.first == "p" {
                // TODO: validdate that the tag looks like a pubkey
                let authorReference = AuthorReference(context: context)
                authorReference.pubkey = jsonTag[safe: 1]
                authorReference.recommendedRelayUrl = jsonTag[safe: 2]
                newAuthorReferences.add(authorReference)
            }
        }
        eventReferences = newEventReferences
        authorReferences = newAuthorReferences
    }
    
    func hydrateMetaData(from jsonEvent: JSONEvent, author newAuthor: Author, context: NSManagedObjectContext) {
        guard createdAt! > newAuthor.lastUpdatedMetadata ?? Date.distantPast else {
            // This is old data
            return
        }
        
        if let contentData = jsonEvent.content.data(using: .utf8) {
            newAuthor.lastUpdatedMetadata = Date(timeIntervalSince1970: TimeInterval(jsonEvent.createdAt))
            // There may be unsupported metadata. Store it to send back later in metadata publishes.
            newAuthor.rawMetadata = contentData

            do {
                let metadata = try JSONDecoder().decode(MetadataEventJSON.self, from: contentData)
                
                // Every event has an author created, so it just needs to be populated
                newAuthor.name = metadata.name
                newAuthor.displayName = metadata.displayName
                newAuthor.about = metadata.about
                newAuthor.profilePhotoURL = metadata.profilePhotoURL
                newAuthor.website = metadata.website
                newAuthor.nip05 = metadata.nip05
                newAuthor.uns = metadata.uns
            } catch {
                print("Failed to decode metaData event with ID \(String(describing: identifier))")
            }
        }
    }

    func markSeen(on relay: Relay) {
        seenOnRelays.insert(relay) 
    }
    
    func hydrateMuteList(from jsonEvent: JSONEvent, context: NSManagedObjectContext) {
        let mutedKeys = jsonEvent.tags.map { $0[1] }
        
        let request = Author.allAuthorsRequest(muted: true)
        
        // Un-Mute anyone (locally only) who is muted but not in the mutedKeys
        if let authors = try? context.fetch(request) {
            for author in authors where !mutedKeys.contains(author.hexadecimalPublicKey!) {
                author.muted = false
                print("Parse-Un-Muted \(author.hexadecimalPublicKey ?? "")")
            }
        }
        
        // Mute anyone (locally only) in the mutedKeys
        for key in mutedKeys {
            if let author = try? Author.find(by: key, context: context) {
                author.muted = true
                print("Parse-Muted \(author.hexadecimalPublicKey ?? "")")
            }
        }
        
        // Force ensure current user never was muted
        Task { @MainActor in
            currentUser.author?.muted = false
        }
    }

    /// Tries to parse a new event out of the given jsonEvent's `content` field.
    @discardableResult
    func parseContent(from jsonEvent: JSONEvent, context: NSManagedObjectContext) -> Event? {
        do {
            if let contentData = jsonEvent.content.data(using: .utf8) {
                let jsonEvent = try JSONDecoder().decode(JSONEvent.self, from: contentData)
                return try Event().createIfNecessary(jsonEvent: jsonEvent, relay: nil, context: context)
            }
        } catch {
            Log.error("Could not parse content for jsonEvent: \(jsonEvent)")
            return nil
        }
        
        return nil
    }
    
    // MARK: - Preloading and Caching
    // Probably should refactor this stuff into a view model
    
    @MainActor var loadingViewData = false
    @MainActor var attributedContent = LoadingContent<AttributedString>.loading
    @MainActor var contentLinks = [URL]()
    @MainActor var relaySubscriptions = SubscriptionCancellables()
    
    /// Instructs this event to load supplementary data like author name and photo, reference events, and produce
    /// formatted `content` and cache it on this object. Idempotent.
    @MainActor func loadViewData() async {
        guard !loadingViewData else {
            return
        }
        loadingViewData = true 
        Log.debug("\(identifier ?? "null") loading view data")
        
        if isStub {
            await loadContent()
            loadingViewData = false
            // TODO: how do we load details for the event again after we hydrate the stub?
        } else {
            Task { await loadReferencedNote() }
            Task { await loadAuthorMetadata() }
            Task { await loadAttributedContent() }
        }
    }
    
    /// Tries to download this event from relays.
    @MainActor private func loadContent() async {
        @Dependency(\.relayService) var relayService
        relaySubscriptions.append(await relayService.requestEvent(with: identifier))
    }
    
    /// Requests any missing metadata for authors referenced by this note from relays.
    @MainActor private func loadAuthorMetadata() async {
        @Dependency(\.relayService) var relayService
        @Dependency(\.persistenceController) var persistenceController
        let backgroundContext = persistenceController.backgroundViewContext
        relaySubscriptions.append(await Event.requestAuthorsMetadataIfNeeded(
            noteID: identifier, 
            using: relayService, 
            in: backgroundContext
        ))
    }
    
    /// Tries to load the note this note is reposting or replying to from relays.
    @MainActor private func loadReferencedNote() async {
        if let referencedNote = referencedNote() {
            await referencedNote.loadViewData()
        } else {
            await rootNote()?.loadViewData()
        }
    }
    
    /// Processes the note `content` to populate mentions and extract links. The results are saved in 
    /// `attributedContent` and `contentLinks`.
    @MainActor func loadAttributedContent() async {
        @Dependency(\.persistenceController) var persistenceController
        let backgroundContext = persistenceController.backgroundViewContext
        if let parsedAttributedContent = await Event.attributedContentAndURLs(
            note: self,
            context: backgroundContext
        ) {
            let (attributedString, contentLinks) = parsedAttributedContent
            self.attributedContent = .loaded(attributedString)
            self.contentLinks = contentLinks
        } else {
            self.attributedContent = .loaded(AttributedString(content ?? "")) 
        }
    }
    
    // MARK: - Helpers
    
    var serializedEventForSigning: [Any?] {
        [
            0,
            author?.hexadecimalPublicKey,
            Int64(createdAt!.timeIntervalSince1970),
            kind,
            allTags,
            content
        ]
    }
    
    /// Returns true if this event doesn't have content. Usually this means we saw it referenced by another event
    /// but we haven't actually downloaded it yet.
    var isStub: Bool {
        author == nil || createdAt == nil 
    }
    
    func calculateIdentifier() throws -> String {
        let serializedEventData = try JSONSerialization.data(
            withJSONObject: serializedEventForSigning,
            options: [.withoutEscapingSlashes]
        )
        return serializedEventData.sha256
    }
    
    func sign(withKey privateKey: KeyPair) throws {
        if allTags == nil {
            allTags = [[String]]() as NSObject
        }
        identifier = try calculateIdentifier()
        if let identifier {
            var serializedBytes = try identifier.bytes
            signature = try privateKey.sign(bytes: &serializedBytes)
        } else {
            Log.error("Couldn't calculate identifier when signing a private key")
        }
    }
    
    var jsonRepresentation: [String: Any]? {
        if let jsonEvent = codable {
            do {
                let data = try JSONEncoder().encode(jsonEvent)
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print("Error encoding event as JSON: \(error.localizedDescription)\n\(self)")
            }
        }
        
        return nil
    }
    
    var jsonString: String? {
        guard let jsonRepresentation,  
            let data = try? JSONSerialization.data(withJSONObject: jsonRepresentation) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
    
    var codable: JSONEvent? {
        guard let identifier = identifier,
            let pubKey = author?.hexadecimalPublicKey,
            let createdAt = createdAt,
            let content = content,
            let signature = signature else {
            return nil
        }
        
        let allTags = (allTags as? [[String]]) ?? []
        
        return JSONEvent(
            id: identifier,
            pubKey: pubKey,
            createdAt: Int64(createdAt.timeIntervalSince1970),
            kind: kind,
            tags: allTags,
            content: content,
            signature: signature
        )
    }
    
    var bech32NoteID: String? {
        guard let identifier = self.identifier,
            let identifierBytes = try? identifier.bytes else {
            return nil
        }
        return Bech32.encode(Nostr.notePrefix, baseEightData: Data(identifierBytes))
    }
    
    var seenOnRelayURLs: [String] {
        seenOnRelays.compactMap { $0.addressURL?.absoluteString }
    }
    
    class func attributedContent(noteID: String?, context: NSManagedObjectContext) async -> AttributedString {
        guard let noteID else {
            return AttributedString()
        }
        
        return await context.perform {
            guard let note = try? Event.findOrCreateStubBy(id: noteID, context: context),
                let content = note.content else {
                return AttributedString()
            }
            try? context.saveIfNeeded()
            let tags = note.allTags as? [[String]] ?? []
            return NoteParser.parse(content: content, tags: tags, context: context)
        }
    }
   
    class func markNoteAsRead(
        noteID: String?,
        context: NSManagedObjectContext
    ) async {
        guard let noteID else {
            Log.unexpected(.missingValue, "markNoteAsRead called without noteID")
            return
        }
        await context.perform {
            guard let event = Event.find(by: noteID, context: context) else {
                Log.unexpected(.incorrectValue, "markNoteAsRead couldn't find event \(noteID)")
                return
            }
            
            event.isRead = true
            do {
                try context.save()
            } catch {
                Log.error("markNoteAsRead error \(error.localizedDescription)")
            }
        }
    }

    /// This function formats an Event's content for display in the UI. It does things like replacing raw npub links
    /// with the author's name, and extracting any URLs so that previews can be displayed for them.
    ///
    /// The given note should be initialized in a main queue NSManagedObjectContext (probably viewContext).
    /// 
    /// - Parameter note: the note whose content should be processed.
    /// - Parameter context: the context to use for database queries - this does not need to be the same context that
    ///     `note` is in.
    /// - Returns: A tuple where the first object is the note content formatted for display, and the second is a list
    ///     of HTTP links found in the note's context.  
    @MainActor class func attributedContentAndURLs(
        note: Event, 
        context: NSManagedObjectContext
    ) async -> (AttributedString, [URL])? {
        guard let content = note.content else {
            return nil
        }
        let tags = note.allTags as? [[String]] ?? []
        
        return await context.perform {
            NoteParser.parse(content: content, tags: tags, context: context)
        }
    }
    
    class func replyMetadata(for noteID: RawEventID?, context: NSManagedObjectContext) async -> (Int, [URL]) {
        guard let noteID else {
            return (0, [])
        }
        
        return await context.perform {
            let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Event.createdAt, ascending: false)]
            fetchRequest.predicate = NSPredicate(format: Event.replyNoteReferences, noteID)
            fetchRequest.includesPendingChanges = false
            fetchRequest.includesSubentities = false
            fetchRequest.relationshipKeyPathsForPrefetching = ["author"]
            let replies = (try? context.fetch(fetchRequest)) ?? []
            let replyCount = replies.count
            
            var avatarURLs = [URL]()
            for reply in replies {
                if let avatarURL = reply.author?.profilePhotoURL,
                    !avatarURLs.contains(avatarURL) {
                    avatarURLs.append(avatarURL)
                    if avatarURLs.count >= 2 {
                        break
                    }
                }
            }
            return (replyCount, avatarURLs)
        }
    }
    
    class func deleteAll(context: NSManagedObjectContext) {
        let deleteRequest = Event.deleteAllEvents()
        
        do {
            try context.execute(deleteRequest)
        } catch let error as NSError {
            print("Failed to delete events. Error: \(error.description)")
        }
    }
    
    /// Returns true if this event tagged the given author.
    func references(author: Author) -> Bool {
        authorReferences.contains(where: { element in
            (element as? AuthorReference)?.pubkey == author.hexadecimalPublicKey
        })
    }
    
    /// Returns true if this event is a reply to an event by the given author.
    func isReply(to author: Author) -> Bool {
        eventReferences.contains(where: { element in
            let rootEvent = (element as? EventReference)?.referencedEvent
            return rootEvent?.author?.hexadecimalPublicKey == author.hexadecimalPublicKey
        })
    }
    
    var isReply: Bool {
        rootNote() != nil || referencedNote() != nil
    }
    
    var isExpired: Bool {
        if let expirationDate {
            return expirationDate <= .now
        } else {
            return false
        }
    }
    
    /// Returns the event this note is directly replying to, or nil if there isn't one.
    func referencedNote() -> Event? {
        if let rootReference = eventReferences.first(where: {
            ($0 as? EventReference)?.type == .reply
        }) as? EventReference,
            let referencedNote = rootReference.referencedEvent {
            return referencedNote
        }
        
        if let lastReference = eventReferences.lastObject as? EventReference,
            lastReference.marker == nil,
            let referencedNote = lastReference.referencedEvent {
            return referencedNote
        }
        return nil
    }
    
    /// Returns the root event of the thread that this note is replying to, or nil if there isn't one.
    func rootNote() -> Event? {
        let rootReference = eventReferences.first(where: {
            ($0 as? EventReference)?.type == .root
        }) as? EventReference
        
        if let rootReference, let rootNote = rootReference.referencedEvent {
            return rootNote
        }
        return nil
    }
    
    /// Returns the event this note is reposting, if this note is a kind 6 repost.
    func repostedNote() -> Event? {
        guard kind == EventKind.repost.rawValue else {
            return nil
        }
        
        if let reference = eventReferences.firstObject as? EventReference,
            let repostedNote = reference.referencedEvent {
            return repostedNote
        }
        
        return nil
    }
    
    /// This tracks which relays this event is deleted on. Hide posts with deletedOn.count > 0
    func trackDelete(on relay: Relay, context: NSManagedObjectContext) throws {
        if EventKind(rawValue: kind) == .delete, let eTags = allTags as? [[String]] {
            for deletedEventId in eTags.map({ $0[1] }) {
                if let deletedEvent = Event.find(by: deletedEventId, context: context),
                    deletedEvent.author?.hexadecimalPublicKey == author?.hexadecimalPublicKey {
                    print("\(deletedEvent.identifier ?? "n/a") was deleted on \(relay.address ?? "unknown")")
                    deletedEvent.deletedOn.insert(relay)
                }
            }
            try context.saveIfNeeded()
        }
    }
    
    class func requestAuthorsMetadataIfNeeded(
        noteID: RawEventID?,
        using relayService: RelayService,
        in context: NSManagedObjectContext
    ) async -> SubscriptionCancellable {
        guard let noteID else {
            return SubscriptionCancellable(subscriptionIDs: [], relayService: relayService)
        }
        
        let requestData: [(RawAuthorID?, Date?)] = await context.perform {
            guard let note = try? Event.findOrCreateStubBy(id: noteID, context: context),
                let authorKey = note.author?.hexadecimalPublicKey else {
                return []
            }
        
            var requestData = [(RawAuthorID?, Date?)]()
            
            guard let author = try? Author.findOrCreate(by: authorKey, context: context) else {
                Log.debug("Author not found when requesting metadata of a note's author")
                return []
            }
            
            if author.needsMetadata {
                requestData.append((author.hexadecimalPublicKey, author.lastUpdatedMetadata))
            }
            
            note.authorReferences.forEach { reference in
                if let reference = reference as? AuthorReference,
                    let pubKey = reference.pubkey,
                    let author = try? Author.findOrCreate(by: pubKey, context: context),
                    author.needsMetadata {
                    requestData.append((author.hexadecimalPublicKey, author.lastUpdatedMetadata))
                }
            }
            
            try? context.saveIfNeeded()
            return requestData
        }
        
        var cancellables = [SubscriptionCancellable]()
        for requestDatum in requestData {
            let authorKey = requestDatum.0
            let sinceDate = requestDatum.1
            cancellables.append(await relayService.requestMetadata(for: authorKey, since: sinceDate))
        }
        
        return SubscriptionCancellable(cancellables: cancellables, relayService: relayService)
    }
    
    var webLink: String {
        if let bech32NoteID {
            return "https://njump.me/\(bech32NoteID)"
        } else {
            Log.error("Couldn't find a bech32note key when generating web link")
            return "https://njump.me"
        }
    }
}
// swiftlint:enable type_body_length
// swiftlint:enable file_length
