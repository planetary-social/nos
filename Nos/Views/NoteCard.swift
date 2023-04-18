//
//  NoteCard.swift
//  Planetary
//
//  Created by Martin Dutra on 25/10/22.
//  Copyright © 2022 Verse Communications Inc. All rights reserved.
//

import SwiftUI
import Logger
import CoreData

/// This view displays the information we have for an message suitable for being used in a list or grid.
///
/// Use this view inside MessageButton to have nice borders.
struct NoteCard: View {

    @ObservedObject var note: Event
    
    var style = CardStyle.compact
    
    @FetchRequest private var likes: FetchedResults<Event>
    @State private var subscriptionIDs = [RelaySubscription.ID]()
    @State private var userTappedShowOutOfNetwork = false
    @State private var replyCount = 0
    @State private var replyAvatarURLs = [URL]()

    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var relayService: RelayService
    @EnvironmentObject private var currentUser: CurrentUser
    let backgroundContext = PersistenceController.backgroundViewContext

    private var showFullMessage: Bool
    private let showReplyCount: Bool
    private var hideOutOfNetwork: Bool
    
    private var author: Author? {
        note.author
    }
    
    private var showContents: Bool {
        !hideOutOfNetwork ||
        userTappedShowOutOfNetwork ||
        currentUser.socialGraph?.contains(note.author?.hexadecimalPublicKey) == true ||
        Event.discoverTabUserIdToInfo.keys.contains(note.author?.hexadecimalPublicKey ?? "")
    }
    
    private var attributedReplies: AttributedString? {
        if replyCount == 0 {
            return nil
        }
        let replyCount = replyCount
        let localized = replyCount == 1 ? Localized.Reply.one : Localized.Reply.many
        let string = localized.text(["count": "**\(replyCount)**"])
        do {
            var attributed = try AttributedString(markdown: string)
            if let range = attributed.range(of: "\(replyCount)") {
                attributed[range].foregroundColor = .primaryTxt
            }
            return attributed
        } catch {
            return nil
        }
    }
      
    var currentUserLikesNote: Bool {
        likes
            .filter {
                $0.author?.hexadecimalPublicKey == currentUser.author?.hexadecimalPublicKey
            }
            .compactMap { $0.eventReferences?.lastObject as? EventReference }
            .contains(where: { $0.eventId == note.identifier })
    }
    
    var likeCount: Int {
        likes
            .compactMap { $0.eventReferences?.lastObject as? EventReference }
            .map { $0.eventId }
            .filter { $0 == note.identifier }
            .count
    }
    
    init(
        note: Event,
        style: CardStyle = .compact,
        showFullMessage: Bool = false,
        hideOutOfNetwork: Bool = true,
        showReplyCount: Bool = true
    ) {
        self.note = note
        self.style = style
        self.showFullMessage = showFullMessage
        self.hideOutOfNetwork = hideOutOfNetwork
        self.showReplyCount = showReplyCount
        _likes = FetchRequest(fetchRequest: Event.likes(noteId: note.identifier!))
    }
    
    var attributedAuthor: AttributedString {
        guard let author else {
            return AttributedString()
        }
        
        var authorName = AttributedString(author.safeName)
        authorName.foregroundColor = .primaryTxt
        authorName.font = Font.clarityBold
        let postedOrRepliedString = note.isReply ? Localized.Reply.replied.string : Localized.Reply.posted.string
        var postedOrReplied = AttributedString(" " + postedOrRepliedString)
        postedOrReplied.foregroundColor = .secondaryTxt
        
        authorName.append(postedOrReplied)
        return authorName
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            switch style {
            case .compact:
                HStack(alignment: .center) {
                    if showContents {
                        Button {
                            if let author {
                                router.currentPath.wrappedValue.append(author)
                            }
                        } label: {
                            HStack(alignment: .center) {
                                AvatarView(imageUrl: author?.profilePhotoURL, size: 24)
                                Text(attributedAuthor)
                                    .lineLimit(1)
                                    .font(.brand)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                if let elapsedTime = note.createdAt?.elapsedTimeFromNowString() {
                                    Text(elapsedTime)
                                        .lineLimit(1)
                                        .font(.body)
                                        .foregroundColor(.secondaryTxt)
                                }
                            }
                        }
                        NoteOptionsButton(note: note)
                    } else {
                        Spacer()
                    }
                }
                .padding(10)
                Divider().overlay(Color.cardDivider).shadow(color: .cardDividerShadow, radius: 0, x: 0, y: 1)
                Group {
                    if note.isStub {
                        HStack {
                            Spacer()
                            ProgressView().foregroundColor(.primaryTxt)
                            Spacer()
                        }
                    } else if showContents {
                        CompactNoteView(note: note, showFullMessage: showFullMessage)
                    } else {
                        VStack {
                            Localized.outsideNetwork.view
                                .font(.body)
                                .foregroundColor(.secondaryTxt)
                                .padding(15)
                            SecondaryActionButton(title: Localized.show) {
                                withAnimation {
                                    userTappedShowOutOfNetwork = true
                                }
                            }
                            .padding(.bottom, 15)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    Divider().overlay(Color.cardDivider).shadow(color: .cardDividerShadow, radius: 0, x: 0, y: 1)
                    HStack {
                        if showReplyCount {
                            StackedAvatarsView(avatarUrls: replyAvatarURLs, size: 20, border: 0)
                            if let replies = attributedReplies {
                                Text(replies)
                                    .font(.subheadline)
                                    .foregroundColor(Color.secondaryTxt)
                            }
                        }
                        Spacer()
                        Image.buttonReply
                        if currentUserLikesNote {
                            Image.buttonLikeActive
                        } else {
                            Button {
                                Task { await likeNote() }
                            } label: {
                                Image.buttonLikeDefault
                            }
                        }
                        if likeCount > 0 {
                            Text(likeCount.description)
                                .font(.body)
                                .foregroundColor(.secondaryTxt)
                        }
                    }
                    .padding(15)
                }
            case .golden:
                if let author {
                    GoldenPostView(author: author, note: note)
                } else {
                    EmptyView()
                }
            }
        }
        .task(priority: .userInitiated) {
            if note.isStub {
                _ = await relayService.requestEvent(with: note.identifier)
            } else if note.isVerified == false, let publicKey = author?.publicKey {
                let verified = try? publicKey.verifySignature(on: note)
                if verified == true {
                    note.isVerified = true
                } else {
                    // TODO: why is this happening on Rabble's profile page?
                    Log.error("Found an unverified event: \(note.identifier!)")
                    viewContext.delete(note)
                }
            }
        }
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
        .background(
            LinearGradient(
                colors: [Color.cardBgTop, Color.cardBgBottom],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .task {
            if showReplyCount {
                let (replyCount, replyAvatarURLs) = await Event.replyMetadata(
                    for: note.identifier, 
                    context: backgroundContext
                )
                self.replyCount = replyCount
                self.replyAvatarURLs = replyAvatarURLs
            }
        }
        .listRowInsets(EdgeInsets())
        .cornerRadius(cornerRadius)
        .padding(padding)
    }
    
    func likeNote() async {
        
        guard let keyPair = currentUser.keyPair else {
            return
        }
        
        var tags: [[String]] = []
        if let eventReferences = note.eventReferences?.array as? [EventReference] {
            // compactMap returns an array of the non-nil results.
            tags += eventReferences.compactMap { event in
                guard let eventId = event.eventId else { return nil }
                return ["e", eventId]
            }
        }

        if let authorReferences = note.authorReferences?.array as? [EventReference] {
            tags += authorReferences.compactMap { author in
                guard let eventId = author.eventId else { return nil }
                return ["p", eventId]
            }
        }

        if let id = note.identifier {
            tags.append(["e", id])
        }
        if let pubKey = author?.publicKey?.hex {
            tags.append(["p", pubKey])
        }
        
        let jsonEvent = JSONEvent(
            id: "",
            pubKey: keyPair.publicKeyHex,
            createdAt: Int64(Date().timeIntervalSince1970),
            kind: 7,
            tags: tags,
            content: "+",
            signature: ""
        )
        do {
            try await relayService.publishToAll(event: jsonEvent, signingKey: keyPair, context: viewContext)
        } catch {
            Log.info("Error creating event for like")
        }
    }

    var padding: EdgeInsets {
        switch style {
        case .golden:
            return EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        case .compact:
            return EdgeInsets(top: 15, leading: 0, bottom: 0, trailing: 0)
        }
    }

    var cornerRadius: CGFloat {
        switch style {
        case .golden:
            return 15
        case .compact:
            return 20
        }
    }
}

struct NoteCard_Previews: PreviewProvider {
    
    static var persistenceController = PersistenceController.preview
    static var previewContext = persistenceController.container.viewContext
    static var router = Router()
    static var emptyPersistenceController = PersistenceController.empty
    static var emptyPreviewContext = emptyPersistenceController.container.viewContext
    static var emptyRelayService = RelayService(persistenceController: emptyPersistenceController)
    
    static var shortNote: Event {
        let note = Event(context: previewContext)
        note.content = "Hello, world!"
        note.author = previewAuthor
        return note
    }
    
    static var imageNote: Event {
        let note = Event(context: previewContext)
        note.content = "Hello, world!https://cdn.ymaws.com/nacfm.com/resource/resmgr/images/blog_photos/footprints.jpg"
        note.author = previewAuthor
        return note
    }
    
    static var verticalImageNote: Event {
        let note = Event(context: previewContext)
        // swiftlint:disable line_length
        note.content = "Hello, world!https://nostr.build/i/nostr.build_1b958a2af7a2c3fcb2758dd5743912e697ba34d3a6199bfb1300fa6be1dc62ee.jpeg"
        // swiftlint:enable line_length
        note.author = previewAuthor
        return note
    }
    
    static var veryWideImageNote: Event {
        let note = Event(context: previewContext)
        // swiftlint:disable line_length
        note.content = "Hello, world! https://nostr.build/i/nostr.build_db8287dde9aedbc65df59972386fde14edf9e1afc210e80c764706e61cd1cdfa.png"
        // swiftlint:enable line_length
        note.author = previewAuthor
        return note
    }
    
    static var previewAuthor = Author(context: previewContext)
    
    static var longNote: Event {
        let note = Event(context: previewContext)
        note.content = .loremIpsum(5)
        let author = Author(context: previewContext)
        // TODO: derive from private key
        author.hexadecimalPublicKey = "32730e9dfcab797caf8380d096e548d9ef98f3af3000542f9271a91a9e3b0001"
        note.author = author
        note.author?.profilePhotoURL = URL(string: "https://avatars.githubusercontent.com/u/1165004?s=40&v=4")
        return note
    }
    
    static var previews: some View {
        Group {
            ScrollView {
                VStack {
                    NoteCard(note: shortNote, hideOutOfNetwork: false)
                    NoteCard(note: longNote, hideOutOfNetwork: false)
                    NoteCard(note: imageNote, hideOutOfNetwork: false)
                    NoteCard(note: verticalImageNote, hideOutOfNetwork: false)
                    NoteCard(note: veryWideImageNote, hideOutOfNetwork: false)
                    NoteCard(note: imageNote, style: .golden, hideOutOfNetwork: false)
                }
            }
        }
        .environment(\.managedObjectContext, emptyPreviewContext)
        .environmentObject(emptyRelayService)
        .environmentObject(router)
        .padding()
        .background(Color.appBg)
    }
}
