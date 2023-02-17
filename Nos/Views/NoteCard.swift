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

    var note: Event
    var style = CardStyle.compact

    private var author: Author? {
        note.author
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            switch style {
            case .compact:
                HStack(alignment: .center) {
                    Button {
                        // TODO: open profile page
                    } label: {
                        HStack(alignment: .center) {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.body)
                                .frame(width: 24, height: 24)
                            Text(note.author?.displayName ?? "")
                                .lineLimit(1)
                                .font(.subheadline)
                                .foregroundColor(Color.secondaryTxt)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    // TODO: Put MessageOptionsButton back here eventually
                }
                .padding(10)
                Divider().overlay(Color.cardDivider).shadow(color: .cardDividerShadow, radius: 0, x: 0, y: 1)
                Group {
                    CompactNoteView(note: note)
                    Divider().overlay(Color.cardDivider).shadow(color: .cardDividerShadow, radius: 0, x: 0, y: 1)
                    HStack {
                        // TODO: Re-enable when we start handling replies
                        // StackedAvatarsView(avatars: replies, size: 20, border: 0)
                        // if let replies = attributedReplies {
                        //     Text(replies)
                        //         .font(.subheadline)
                        //         .foregroundColor(Color.secondaryTxt)
                        // }
                        Text("unknown replies")
                        Spacer()
                        // Image.buttonReply
                    }
                    .padding(15)
                }
            case .golden:
                // TODO: add back when we add Discover screen:
                // GoldenPostView(identifier: message.id, post: post, author: author)
                Text("golden style not supported")
            }
        }
        .background(
            LinearGradient(
                colors: [Color.cardBgTop, Color.cardBgBottom],
                startPoint: .top,
                endPoint: .bottom
            )
        )
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

//    private var replies: [ImageMetadata] {
//        Array(message.metadata.replies.abouts.compactMap { $0.image }.prefix(2))
//    }

//    private var attributedReplies: AttributedString? {
//        let replyCount = message.metadata.replies.count
//        let localized = replyCount == 1 ? Localized.Reply.one : Localized.Reply.many
//        let string = localized.text(["count": "**\(replyCount)**"])
//        do {
//            var attributed = try AttributedString(markdown: string)
//            if let range = attributed.range(of: "\(replyCount)") {
//                attributed[range].foregroundColor = .primaryTxt
//            }
//            return attributed
//        } catch {
//            return nil
//        }
//    }
}

struct NoteCard_Previews: PreviewProvider {
    
    static var persistenceController = PersistenceController.preview
    static var previewContext = persistenceController.container.viewContext
    
    static var shortNote: Event {
        let note = Event(context: previewContext)
        note.content = "Hello, world!"
        return note
    }
    
    static var longNote: Event {
        let note = Event(context: previewContext)
        note.content = .loremIpsum(5)
        let author = Author(context: previewContext)
        // TODO: derive from private key
        author.hexadecimalPublicKey = "32730e9dfcab797caf8380d096e548d9ef98f3af3000542f9271a91a9e3b0001"
        note.author = author
        return note
    }
    
        static var previews: some View {
            Group {
                ScrollView {
                    VStack {
                        NoteCard(note: shortNote)
                        NoteCard(note: longNote)
                    }
                }
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
                        NoteCard(note: shortNote)
                        NoteCard(note: longNote)
                    }
                }
                ScrollView {
                    VStack {
                        NoteCard(note: shortNote)
                        NoteCard(note: longNote)
                    }
                }
                .preferredColorScheme(.dark)
            }
            .padding()
            .background(Color.appBg)
        }
}
