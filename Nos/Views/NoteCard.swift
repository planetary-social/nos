//
//  NoteCard.swift
//  Planetary
//
//  Created by Martin Dutra on 25/10/22.
//  Copyright © 2022 Verse Communications Inc. All rights reserved.
//

import SwiftUI

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

    var style = CardStyle.compact
    
    var repliesRequest: FetchRequest<Event>
    var replies: FetchedResults<Event> { repliesRequest.wrappedValue }
    
    @ObservedObject private var currentUser: CurrentUser = .shared
    
    @State private var userTappedShowOutOfNetwork = false
    
    var showContents: Bool {
        !hideOutOfNetwork ||
        userTappedShowOutOfNetwork ||
        currentUser.inNetworkAuthors.contains(note.author!) ||
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
                                Text(author.safeName)
                                    .lineLimit(1)
                                    .font(.subheadline)
                                    .foregroundColor(Color.secondaryTxt)
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
                            Text("This user is outside your network.")
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
                    }
                    .padding(15)
                }
            case .golden:
                GoldenPostView(author: author, note: note)
            }
        }
        .task {
            if author.needsMetadata {
                _ = author.requestMetadata(using: relayService)
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
                    NoteCard(author: previewAuthor, note: shortNote)
                    NoteCard(author: previewAuthor, note: longNote)
                }
            }
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
                    NoteCard(author: previewAuthor, note: shortNote)
                    NoteCard(author: previewAuthor, note: longNote)
                }
            }
            ScrollView {
                VStack {
                    NoteCard(author: previewAuthor, note: shortNote)
                    NoteCard(author: previewAuthor, note: longNote)
                }
            }
            .preferredColorScheme(.dark)
        }
        .environment(\.managedObjectContext, emptyPreviewContext)
        .environmentObject(emptyRelayService)
        .environmentObject(router)
        .padding()
        .background(Color.appBg)
    }
}
