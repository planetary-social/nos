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
import Dependencies

/// This view displays the information we have for an message suitable for being used in a list or grid.
///
/// Use this view inside MessageButton to have nice borders.
struct NoteCard: View {

    @ObservedObject var note: Event
    
    var style = CardStyle.compact
    
    @State private var subscriptionIDs = [RelaySubscription.ID]()
    @State private var userTappedShowOutOfNetwork = false
    @State private var replyCount = 0
    @State private var replyAvatarURLs = [URL]()

    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var relayService: RelayService
    @EnvironmentObject private var currentUser: CurrentUser
    @Dependency(\.persistenceController) var persistenceController

    private var showFullMessage: Bool
    private let showReplyCount: Bool
    private var hideOutOfNetwork: Bool
    private var replyAction: ((Event) -> Void)?
    
    private var showContents: Bool {
        !hideOutOfNetwork ||
        userTappedShowOutOfNetwork ||
        currentUser.socialGraph.contains(note.author?.hexadecimalPublicKey) ||
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
    
    init(
        note: Event,
        style: CardStyle = .compact,
        showFullMessage: Bool = false,
        hideOutOfNetwork: Bool = true,
        showReplyCount: Bool = true,
        replyAction: ((Event) -> Void)? = nil
    ) {
        self.note = note
        self.style = style
        self.showFullMessage = showFullMessage
        self.hideOutOfNetwork = hideOutOfNetwork
        self.showReplyCount = showReplyCount
        self.replyAction = replyAction
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            switch style {
            case .compact:
                HStack(alignment: .center, spacing: 0) {
                    if showContents, let author = note.author {
                        Button {
                            router.currentPath.wrappedValue.append(author)
                        } label: {
                            NoteCardHeader(note: note, author: author)
                        }
                        NoteOptionsButton(note: note)
                    } else {
                        Spacer()
                    }
                }
                Divider().overlay(Color.cardDivider).shadow(color: .cardDividerShadow, radius: 0, x: 0, y: 1)
                Group {
                    if note.isStub {
                        HStack {
                            Spacer()
                            ProgressView().foregroundColor(.primaryTxt)
                            Spacer()
                        }
                        .padding(30)
                    } else if showContents {
                        CompactNoteView(note: note, showFullMessage: showFullMessage)
                    } else {
                        VStack {
                            Localized.outsideNetwork.view
                                .font(.body)
                                .foregroundColor(.secondaryText)
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
                    BeveledSeparator()
                    HStack(spacing: 0) {
                        if showReplyCount {
                            StackedAvatarsView(avatarUrls: replyAvatarURLs, size: 20, border: 0)
                                .padding(.trailing, 8)
                            if let replies = attributedReplies {
                                Text(replies)
                                    .font(.subheadline)
                                    .foregroundColor(Color.secondaryText)
                            }
                        }
                        Spacer()
                        
                        RepostButton(note: note) {
                            await repostNote()
                        }
                        
                        LikeButton(note: note)

                        ReplyButton(note: note, replyAction: replyAction)
                    }
                    .padding(.leading, 13)
                }
            case .golden:
                if let author = note.author {
                    GoldenPostView(author: author, note: note)
                } else {
                    EmptyView()
                }
            }
        }
        .task(priority: .userInitiated) {
            if note.isStub {
                _ = await relayService.requestEvent(with: note.identifier)
            } 
        }
        .onAppear {
            Task(priority: .userInitiated) {
                await subscriptionIDs += Event.requestAuthorsMetadataIfNeeded(
                    noteID: note.identifier,
                    using: relayService,
                    in: persistenceController.backgroundViewContext
                )
            }
        }
        .onDisappear {
            Task(priority: .userInitiated) {
                await relayService.decrementSubscriptionCount(for: subscriptionIDs)
                subscriptionIDs.removeAll()
            }
        }
        .background(LinearGradient.cardBackground)
        .task {
            if showReplyCount {
                let (replyCount, replyAvatarURLs) = await Event.replyMetadata(
                    for: note.identifier, 
                    context: persistenceController.backgroundViewContext
                )
                self.replyCount = replyCount
                self.replyAvatarURLs = replyAvatarURLs
            }
        }
        .listRowInsets(EdgeInsets())
        .cornerRadius(cornerRadius)
    }
    
    func repostNote() async {
        guard let keyPair = currentUser.keyPair else {
            return
        }
        
        var tags: [[String]] = []
        if let id = note.identifier {
            tags.append(["e", id] + note.seenOnRelayURLs)
        }
        if let pubKey = note.author?.publicKey?.hex {
            tags.append(["p", pubKey])
        }
        
        let jsonEvent = JSONEvent(
            pubKey: keyPair.publicKeyHex,
            kind: .repost,
            tags: tags,
            content: note.jsonString ?? ""
        )
        
        do {
            try await relayService.publishToAll(event: jsonEvent, signingKey: keyPair, context: viewContext)
        } catch {
            Log.info("Error creating event for like")
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
    
    static var previewData = PreviewData()
    static var previews: some View {
        Group {
            ScrollView {
                VStack {
                    NoteCard(note: previewData.longFormNote, hideOutOfNetwork: false)
                    NoteCard(note: previewData.shortNote, hideOutOfNetwork: false)
                    NoteCard(note: previewData.longNote, hideOutOfNetwork: false)
                    NoteCard(note: previewData.imageNote, hideOutOfNetwork: false)
                    NoteCard(note: previewData.expiringNote, hideOutOfNetwork: false)
                    NoteCard(note: previewData.verticalImageNote, hideOutOfNetwork: false)
                    NoteCard(note: previewData.veryWideImageNote, hideOutOfNetwork: false)
                    NoteCard(note: previewData.imageNote, style: .golden, hideOutOfNetwork: false)
                    NoteCard(note: previewData.linkNote, hideOutOfNetwork: false)
                }
            }
        }
        .environment(\.managedObjectContext, previewData.previewContext)
        .environmentObject(previewData.relayService)
        .environmentObject(previewData.router)
        .environmentObject(previewData.currentUser)
        .padding()
        .background(Color.appBg)
    }
}
