//
//  NoteCard.swift
//  Planetary
//
//  Created by Martin Dutra on 25/10/22.
//  Copyright © 2022 Verse Communications Inc. All rights reserved.
//

import SwiftUI
import Logger

/// This view displays the information we have for an message suitable for being used in a list or grid.
///
/// Use this view inside MessageButton to have nice borders.
struct NoteCard: View {

    @ObservedObject var author: Author
    
    @ObservedObject var note: Event {
        didSet {
            if let eventAuthor = note.author {
                self.author = eventAuthor
            }
        }
    }
    
    @Environment(\.managedObjectContext) private var viewContext

    var style = CardStyle.compact
    
    var repliesRequest: FetchRequest<Event>
    var replies: FetchedResults<Event> { repliesRequest.wrappedValue }
    
    @FetchRequest private var likes: FetchedResults<Event>
    
    @ObservedObject private var currentUser: CurrentUser = .shared
    
    @State private var userTappedShowOutOfNetwork = false
    
    var showContents: Bool {
        !hideOutOfNetwork ||
        userTappedShowOutOfNetwork ||
        currentUser.inNetworkAuthors.contains(where: {
            $0.hexadecimalPublicKey == note.author!.hexadecimalPublicKey
        }) ||
        Event.discoverTabUserIdToInfo.keys.contains(note.author?.hexadecimalPublicKey ?? "")
    }
    
    var replyAvatarUrls: [URL?] {
        var uniqueAuthors: [Author] = []
        var added = Set<Author?>()
        for author in replies.compactMap({ $0.author }) where !added.contains(author) {
            uniqueAuthors.append(author)
            added.insert(author)
        }
        return Array(uniqueAuthors.map { $0.profilePhotoURL }.prefix(2))
    }
    
    private var attributedReplies: AttributedString? {
        if replies.isEmpty {
            return nil
        }
        let replyCount = replies.count
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
    
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var relayService: RelayService
    
    private var showFullMessage: Bool
    private let showReplyCount: Bool
    private var hideOutOfNetwork: Bool
    
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
        author: Author,
        note: Event,
        style: CardStyle = .compact,
        showFullMessage: Bool = false,
        hideOutOfNetwork: Bool = true,
        showReplyCount: Bool = true
    ) {
        self.author = author
        self.note = note
        self.style = style
        self.showFullMessage = showFullMessage
        self.hideOutOfNetwork = hideOutOfNetwork
        self.showReplyCount = showReplyCount
        if showReplyCount {
            self.repliesRequest = FetchRequest(fetchRequest: Event.allReplies(to: note), animation: .default)
        } else {
            self.repliesRequest = FetchRequest(fetchRequest: Event.emptyRequest())
        }
        _likes = FetchRequest(fetchRequest: Event.likes(noteId: note.identifier!))
    }
    
    var attributedAuthor: AttributedString {
        var authorName = AttributedString(author.safeName)
        authorName.foregroundColor = .primaryTxt
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
                            router.currentPath.wrappedValue.append(author)
                        } label: {
                            HStack(alignment: .center) {
                                AvatarView(imageUrl: author.profilePhotoURL, size: 24)
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
                    if showContents {
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
                            StackedAvatarsView(avatarUrls: replyAvatarUrls, size: 20, border: 0)
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
                GoldenPostView(author: author, note: note)
            }
        }
        .task {
            note.requestAuthorsMetadataIfNeeded(using: relayService, in: viewContext)

            if note.isVerified == false, let publicKey = author.publicKey {
                let verified = try? publicKey.verifySignature(on: note)
                if verified != true {
                    Log.error("Found an unverified event: \(note.identifier!)")
                    viewContext.delete(note)
                } else {
                    note.isVerified = true
                }
            }
        }
        .background(
            LinearGradient(
                colors: [Color.cardBgTop, Color.cardBgBottom],
                startPoint: .top,
                endPoint: .bottom
            )
        )
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
        if let pubKey = author.publicKey?.hex {
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
            let event = try await Event.findOrCreate(jsonEvent: jsonEvent, relay: nil, context: viewContext)
            try event.sign(withKey: keyPair)
            try viewContext.save()
            relayService.publishToAll(event: event, context: viewContext)
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
                    NoteCard(author: previewAuthor, note: shortNote, hideOutOfNetwork: false)
                    NoteCard(author: previewAuthor, note: longNote, hideOutOfNetwork: false)
                    NoteCard(author: previewAuthor, note: imageNote, hideOutOfNetwork: false)
                    NoteCard(author: previewAuthor, note: verticalImageNote, hideOutOfNetwork: false)
                    NoteCard(author: previewAuthor, note: veryWideImageNote, hideOutOfNetwork: false)
                    NoteCard(author: previewAuthor, note: imageNote, style: .golden, hideOutOfNetwork: false)
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
