import SwiftUI
import Foundation
import Dependencies
import CoreData

// swiftlint:disable line_length force_try

/// A set of test data and an environment that can be used to display Core Data objects in SwiftUI Previews. This 
/// includes an in-memory persistent store and mocked versions of other singletons like `Router` and `RelayService`.
/// 
/// Instantiate an instance as a `static var` in a preview
/// and inject it into the view using the `inject(previewData:)` view modifier.
struct PreviewData {
    
    let currentUserKey: KeyPair 
    
    init(currentUserKey: KeyPair = KeyFixture.keyPair) {
        self.currentUserKey = currentUserKey
        Task { [currentUser] in
            await currentUser.setPrivateKeyHex(currentUserKey.privateKeyHex)
        }
    }
    
    // MARK: - Environment
    @Dependency(\.persistenceController) var persistenceController 
    @Dependency(\.router) var router
    @Dependency(\.relayService) var relayService
    @Dependency(\.currentUser) var currentUser
    
    lazy var previewContext: NSManagedObjectContext = {
        persistenceController.viewContext  
    }()
    
    // MARK: - Authors
    
    lazy var previewAuthor: Author = {
        alice
    }()
    
    lazy var alice: Author = {
        let author = try! Author.findOrCreate(by: KeyFixture.alice.publicKeyHex, context: previewContext)
        author.name = "Alice"
        author.nip05 = "alice@nos.social"
        author.profilePhotoURL = URL(string: "https://github.com/planetary-social/nos/assets/1165004/07f83f00-4555-4db3-85fc-f1a05b1908a2")
        author.about = """
        Bitcoin Maximalist extraordinaire! 🚀 HODLing since the days of Satoshi's personal phone number. Always clad in my 'Bitcoin or Bust' t-shirt, preaching the gospel of the Orange Coin. 🍊 Lover of decentralized currencies, disruptive technology, and long walks on the blockchain. 💪 When I'm not evangelizing BTC, you'll find me stacking sats, perfecting my lambo moonwalk, and dreaming of a world ruled by blockchain memes. 💸 Join me on this rollercoaster ride to financial freedom, where we laugh at the mere mortals still stuck with fiat. #BitcoinFTW #WhenLambo 🚀
        """
        return author
    }()
    
    lazy var bob: Author = {
        let author = try! Author.findOrCreate(by: KeyFixture.bob.publicKeyHex, context: previewContext)
        author.hexadecimalPublicKey = KeyFixture.bob.publicKeyHex
        author.name = "Bob"
        author.profilePhotoURL = URL(string: "https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Ftse1.mm.bing.net%2Fth%3Fid%3DOIP.r1ZOH5E3M6WiK6aw5GRdlAHaEK%26pid%3DApi&f=1&ipt=42ae9de7730da3bda152c5980cd64b14ccef37d8f55b8791e41b4667fc38ddf1&ipo=images")
        
        return author
    }()
    
    lazy var eve: Author = {
        let author = try! Author.findOrCreate(by: KeyFixture.eve.publicKeyHex, context: previewContext)
        author.name = "Eve"
        author.nip05 = "eve@nos.social"
        
        return author
    }()
    
    lazy var blockedUser: Author = {
        let author = try! Author.findOrCreate(by: KeyFixture.eve.publicKeyHex, context: previewContext)
        author.name = "Sam"
        author.about = "I am a terrible person"
        author.muted = true
        author.nip05 = "sam@nos.social"
        
        return author
    }()
    
    // MARK: - Notes
    
    lazy var shortNote: Event = {
        let note = Event(context: previewContext)
        note.identifier = "1"
        note.kind = EventKind.text.rawValue
        note.content = "Hello, world!"
        note.author = previewAuthor
        note.createdAt = .now
        try? previewContext.save()
        return note
    }()
    
    lazy var expiringNote: Event = {
        let note = Event(context: previewContext)
        note.identifier = "10"
        note.kind = EventKind.text.rawValue
        note.content = "Hello, world!"
        note.author = previewAuthor
        note.createdAt = .now
        let currentDate = Date() 
        let calendar = Calendar.current 
        var dateComponents = DateComponents() 
        dateComponents.day = 1 
        let tomorrow = calendar.date(byAdding: dateComponents, to: currentDate)!
        note.expirationDate = tomorrow
        try? previewContext.save()
        return note
    }()
    
    lazy var imageNote: Event = {
        let note = Event(context: previewContext)
        note.identifier = "2"
        note.kind = EventKind.text.rawValue
        note.content = "Hello, world!https://cdn.ymaws.com/nacfm.com/resource/resmgr/images/blog_photos/footprints.jpg"
        note.author = previewAuthor
        note.createdAt = .now
        try? previewContext.save()
        return note
    }()
    
    lazy var verticalImageNote: Event = {
        let note = Event(context: previewContext)
        note.identifier = "3"
        note.kind = EventKind.text.rawValue
        note.content = "Hello, world!https://nostr.build/i/nostr.build_1b958a2af7a2c3fcb2758dd5743912e697ba34d3a6199bfb1300fa6be1dc62ee.jpeg"
        note.author = previewAuthor
        note.createdAt = .now
        try? previewContext.save()
        return note
    }()
    
    lazy var veryWideImageNote: Event = {
        let note = Event(context: previewContext)
        note.identifier = "4"
        note.kind = EventKind.text.rawValue
        note.content = "Hello, world! https://nostr.build/i/nostr.build_db8287dde9aedbc65df59972386fde14edf9e1afc210e80c764706e61cd1cdfa.png"
        note.author = previewAuthor
        note.createdAt = .now
        try? previewContext.save()
        return note
    }()
    
    lazy var longNote: Event = {
        let note = Event(context: previewContext)
        note.identifier = "5"
        note.kind = EventKind.text.rawValue
        note.createdAt = .now
        note.content = .loremIpsum(5)
        note.author = previewAuthor
        try? previewContext.save()
        return note
    }()
    
    lazy var longFormNote: Event = {
        let note = Event(context: previewContext)
        note.identifier = "6"
        note.createdAt = .now
        note.kind = EventKind.longFormContent.rawValue
        note.content = 
        """
        # This note
        
        is **formatted** with
        > _markdown_
        
        And it has a link to [nos.social](https://nos.social).
        """
        note.author = previewAuthor
        try? previewContext.save()
        return note
    }()
    
    lazy var doubleImageNote: Event = {
        let note = Event(context: previewContext)
        note.identifier = "7"
        note.kind = EventKind.text.rawValue
        note.content = """
        Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore 
        magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. 
        
        Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
        https://cdn.ymaws.com/nacfm.com/resource/resmgr/images/blog_photos/footprints.jpg
        https://nostr.build/i/nostr.build_1b958a2af7a2c3fcb2758dd5743912e697ba34d3a6199bfb1300fa6be1dc62ee.jpeg
        """
        note.author = previewAuthor
        note.createdAt = .now
        try? previewContext.save()
        return note
    }()
    
    lazy var linkNote: Event = {
        let note = Event(context: previewContext)
        note.identifier = "8"
        note.kind = EventKind.text.rawValue
        note.content = """
        Wsg fam! 🤙🫂
        Free sats await at the end, please read carefully ✨️
        
        We are officially out of the top 40 on nostr:npub1yfg0d955c2jrj2080ew7pa4xrtj7x7s7umt28wh0zurwmxgpyj9shwv6vg
        Helluva drop from #7
        
        I need your help! 🥺
        
        Please, go boost my songs (as little as 1 sat) 💜
        
        https://www.wavlake.com/chu-t
        
        I'll give 100 sats to everyone who boosts this post
        
        Love y'all 🫶
        """
        note.author = previewAuthor
        note.createdAt = .now
        try? previewContext.save()
        return note
    }()
    
    lazy var repost: Event = {
        let originalPostAuthor = Author(context: previewContext)
        originalPostAuthor.hexadecimalPublicKey = KeyFixture.bob.publicKeyHex
        originalPostAuthor.name = "Bob"
        originalPostAuthor.profilePhotoURL = URL(string: "https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Ftse1.mm.bing.net%2Fth%3Fid%3DOIP.r1ZOH5E3M6WiK6aw5GRdlAHaEK%26pid%3DApi&f=1&ipt=42ae9de7730da3bda152c5980cd64b14ccef37d8f55b8791e41b4667fc38ddf1&ipo=images")

        let repostedNote = Event(context: previewContext)
        repostedNote.identifier = "3"
        repostedNote.kind = EventKind.text.rawValue
        repostedNote.createdAt = .now
        repostedNote.content = "Please repost this Alice"
        repostedNote.author = originalPostAuthor

        let reference: EventReference
        do {
            reference = try EventReference(jsonTag: ["e", "3", ""], context: previewContext)
        } catch {
            print(error)
            reference = EventReference(context: previewContext)
        }
        
        let repost = Event(context: previewContext)
        repost.identifier = "4"
        repost.kind = EventKind.repost.rawValue
        repost.createdAt = .now
        repost.author = previewAuthor
        repost.eventReferences = NSOrderedSet(array: [reference])
        try? previewContext.save()
        return repost
    }()
    
    lazy var reply: Event = {
        let rootNote = longNote
        
        let note = Event(context: previewContext)
        note.identifier = "11"
        note.kind = EventKind.text.rawValue
        note.content = "Well that's pretty neat"
        note.author = bob
        note.createdAt = .now
        
        let rootReference = EventReference(context: previewContext)
        rootReference.eventId = rootNote.identifier
        rootReference.marker = "root"
        rootReference.referencedEvent = rootNote
        
        note.insertIntoEventReferences(rootReference, at: 0)
        
        try? previewContext.save()
        return note
    }()
    
    // MARK: Reports
    
    lazy var shortNoteReportOne: Event = {
        let note = Event(context: previewContext)
        note.identifier = "r1"
        note.kind = EventKind.report.rawValue
        note.content = "impersonation"
        note.author = bob
        note.createdAt = .now
        
        let reference = EventReference(context: previewContext)
        reference.eventId = "1"
        reference.referencedEvent = shortNote
        note.insertIntoEventReferences(reference, at: 0)
        
        try? previewContext.save()
        return note
    }()
    
    lazy var reportBobTwo: Event = {
        let note = Event(context: previewContext)
        note.identifier = "r4"
        note.kind = EventKind.report.rawValue
        note.content = "harassment"
        note.author = bob
        note.createdAt = .now
        
        let reference = EventReference(context: previewContext)
        reference.eventId = "1"
        reference.referencedEvent = shortNote
        note.insertIntoEventReferences(reference, at: 0)
        
        try? previewContext.save()
        return note
    }()
    
    lazy var shortNoteReportTwo: Event = {
        let note = Event(context: previewContext)
        note.identifier = "r2"
        note.kind = EventKind.report.rawValue
        note.content = "harassment"
        note.allTags = [
            [ "p", "6b165e83a3b7d333a6e7db1f200dc627e31eb5170285c29ded271be203c5da37", "other"]
        ] as NSObject
        note.author = eve
        note.createdAt = .now
        
        let reference = EventReference(context: previewContext)
        reference.eventId = "1"
        reference.referencedEvent = shortNote
        note.insertIntoEventReferences(reference, at: 0)
        
        try? previewContext.save()
        return note
    }()

    lazy var shortNoteReportThree: Event = {
        let note = Event(context: previewContext)
        note.identifier = "r3"
        note.kind = EventKind.report.rawValue
        note.content = "this person is spammy"
        note.allTags = [
            [ "p", "6b165e83a3b7d333a6e7db1f200dc627e31eb5170285c29ded271be203c5da37", "spam" ],
            [ "e", "ad0cea87d9c81e3bc5b15ddf561b1a2bbbff3d8318d4ea9ccd4644def9e035b8", "spam" ],
        ] as NSObject
        note.author = alice
        note.createdAt = .now

        let reference = EventReference(context: previewContext)
        reference.eventId = "1"
        reference.referencedEvent = shortNote
        note.insertIntoEventReferences(reference, at: 0)

        try? previewContext.save()
        return note
    }()
    
    // MARK: - Streams
    
    lazy var streamImageOne: Event = {
        let note = Event(context: previewContext)
        note.identifier = "stream1"
        note.kind = EventKind.streamPhoto.rawValue
        note.content = "https://media.tacdn.com/media/attractions-splice-spp-674x446/0a/ff/66/e5.jpg"
        note.author = bob
        note.createdAt = .now
        note.allTags = [["s": "#uruguay"]] as NSObject
        return note
    }()
    
    lazy var streamImageTwo: Event = {
        let note = Event(context: previewContext)
        note.identifier = "stream2"
        note.kind = EventKind.streamPhoto.rawValue
        note.content = "https://www.cunard.com/content/dam/cunard/inventory-assets/ports/MVD/MVD.jpg"
        note.author = bob
        note.createdAt = .now
        note.allTags = [["s": "#uruguay"]] as NSObject
        return note
    }()
    
    lazy var streamImageThree: Event = {
        let note = Event(context: previewContext)
        note.identifier = "stream3"
        note.kind = EventKind.streamPhoto.rawValue
        note.content = "https://d1bvpoagx8hqbg.cloudfront.net/originals/experience-montevideo-uruguay-1ad4b9998fbce78bf83d7db2798a922f.jpg"
        note.author = bob
        note.createdAt = .now
        note.allTags = [["s": "#uruguay"]] as NSObject
        return note
    }()
}

struct InjectPreviewData: ViewModifier {
    
    @State var previewData: PreviewData
    
    func body(content: Content) -> some View {
        content
            .environment(\.managedObjectContext, previewData.persistenceController.viewContext)
            .environmentObject(previewData.router)
            .environmentObject(previewData.relayService)
            .environment(previewData.currentUser)
    }
}

extension View {
    func inject(previewData: PreviewData) -> some View {
        self.modifier(InjectPreviewData(previewData: previewData))
    }
}

// swiftlint:enable line_length force_try
