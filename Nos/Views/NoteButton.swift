//
//  Notebutton.swift
//  Nos
//
//  Created by Jason Cheatham on 2/16/23.
//

import Foundation
import SwiftUI
import CoreData

/// This view displays the a button with the information we have for a note suitable for being used in a list
/// or grid.
///
/// The button opens the ThreadView for the note when tapped.
struct NoteButton: View {

    var note: Event
    var style = CardStyle.compact
    var showFullMessage = false
    var hideOutOfNetwork = true
    var allowsPush = true
    var showReplyCount = true
    var isInThreadView = false

    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var relayService: RelayService
    
    @State private var subscriptionIDs = [RelaySubscription.ID]()
    let backgroundContext = PersistenceController.backgroundViewContext

    init(
        note: Event, 
        style: CardStyle = CardStyle.compact, 
        showFullMessage: Bool = false, 
        hideOutOfNetwork: Bool = true, 
        allowsPush: Bool = true, 
        showReplyCount: Bool = true, 
        isInThreadView: Bool = false
    ) {
        self.note = note
        self.style = style
        self.showFullMessage = showFullMessage
        self.hideOutOfNetwork = hideOutOfNetwork
        self.allowsPush = allowsPush
        self.showReplyCount = showReplyCount
        self.isInThreadView = isInThreadView
    }

    /// The note displayed in the note card. Could be different from `note` i.e. in the case of a repost.
    var displayedNote: Event {
        if note.kind == EventKind.repost.rawValue,
            let repostedNote = note.referencedNote() {
            return repostedNote
        } else {
            return note
        }
    }

    var body: some View {
        VStack {
            if note.kind == EventKind.repost.rawValue {
                let repost = note
                Button(action: { 
                    if let author = repost.author {
                        router.push(author)
                    }
                }, label: { 
                    HStack(alignment: .center) {
                        AvatarView(imageUrl: repost.author?.profilePhotoURL, size: 24)
                        Text((repost.author?.safeName ?? "error"))
                            .lineLimit(1)
                            .font(.brand)
                            .bold()
                            .foregroundColor(.primaryTxt)
                        Image.repostSymbol
                        if let elapsedTime = repost.createdAt?.elapsedTimeFromNowString() {
                            Text(elapsedTime)
                                .lineLimit(1)
                                .font(.body)
                                .foregroundColor(.secondaryTxt)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    .readabilityPadding()
                    .onAppear {
                        Task(priority: .userInitiated) {
                            await subscriptionIDs += Event.requestAuthorsMetadataIfNeeded(
                                noteID: note.identifier,
                                using: relayService,
                                in: backgroundContext
                            )
                        }
                    }
                    .onDisappear {
                        Task(priority: .userInitiated) {
                            await relayService.removeSubscriptions(for: subscriptionIDs)
                            subscriptionIDs.removeAll()
                        }
                    }
                })
            }
            
            Button {
                if allowsPush {
                    if !isInThreadView, let referencedNote = displayedNote.referencedNote() {
                        router.push(referencedNote)
                    } else {
                        router.push(displayedNote)
                    }
                }
            } label: {
                NoteCard(
                    note: displayedNote,
                    style: style,
                    showFullMessage: showFullMessage,
                    hideOutOfNetwork: hideOutOfNetwork,
                    showReplyCount: showReplyCount
                )
                .padding(.horizontal)
                .readabilityPadding()
            }
            .buttonStyle(CardButtonStyle())
        }
    }
}

struct NoteButton_Previews: PreviewProvider {
   
    static var persistenceController = PersistenceController.preview
    static var previewContext = persistenceController.container.viewContext
    static var router = Router()
    static var relayService = RelayService(persistenceController: persistenceController)

    static var currentUser: CurrentUser = {
        let currentUser = CurrentUser(persistenceController: persistenceController)
        currentUser.viewContext = previewContext
        currentUser.relayService = relayService
        Task { await currentUser.setKeyPair(KeyFixture.keyPair) }
        return currentUser
    }()
    
    static var previewAuthor: Author = {
        let author = Author(context: previewContext)
        author.hexadecimalPublicKey = KeyFixture.alice.publicKeyHex
        author.name = "Alice"
        author.profilePhotoURL = URL(string: "https://avatars.githubusercontent.com/u/1165004?s=40&v=4")
        return author
    }()

    static var shortNote: Event {
        let note = Event(context: previewContext)
        note.identifier = "1"
        note.createdAt = .now
        note.content = "Hello, world!"
        note.author = previewAuthor
        try! previewContext.save()
        return note
    }
    
    static var longNote: Event {
        let note = Event(context: previewContext)
        note.identifier = "2"
        note.createdAt = .now
        note.content = .loremIpsum(5)
        let author = Author(context: previewContext)
        // TODO: derive from private key
        author.hexadecimalPublicKey = "32730e9dfcab797caf8380d096e548d9ef98f3af3000542f9271a91a9e3b0001"
        note.author = author
        try! previewContext.save()
        return note
    }

    static var repost: Event {
        let originalPostAuthor = Author(context: previewContext)
        originalPostAuthor.hexadecimalPublicKey = KeyFixture.bob.publicKeyHex
        originalPostAuthor.name = "Bob"
        originalPostAuthor.profilePhotoURL = URL(string: "https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Ftse1.mm.bing.net%2Fth%3Fid%3DOIP.r1ZOH5E3M6WiK6aw5GRdlAHaEK%26pid%3DApi&f=1&ipt=42ae9de7730da3bda152c5980cd64b14ccef37d8f55b8791e41b4667fc38ddf1&ipo=images")

        let repostedNote = Event(context: previewContext)
        repostedNote.identifier = "3"
        repostedNote.createdAt = .now
        repostedNote.content = "Please repost this Alice"
        repostedNote.author = originalPostAuthor
        
        let reference = try! EventReference(jsonTag: ["e", "3", ""], context: previewContext)

        let repost = Event(context: previewContext)
        repost.identifier = "4"
        repost.kind = EventKind.repost.rawValue
        repost.createdAt = .now
        repost.author = previewAuthor
        repost.eventReferences = NSOrderedSet(array: [reference])
        try! previewContext.save()
        return repost
    }
    
    static var previews: some View {
        VStack {
            NoteButton(note: repost, hideOutOfNetwork: false)
            NoteButton(note: shortNote)
            NoteButton(note: shortNote, style: .golden)
            NoteButton(note: longNote)
        }
        .environment(\.managedObjectContext, previewContext)
        .environmentObject(relayService)
        .environmentObject(router)
        .environmentObject(currentUser)
    }
}
