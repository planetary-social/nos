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
                            Text(note.content ?? "")
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
//                    CompactPostView(identifier: message.id, post: post)
                    Divider().overlay(Color.cardDivider).shadow(color: .cardDividerShadow, radius: 0, x: 0, y: 1)
                    HStack {
                        // TODO: Re-enable when we start handling replies
//                        StackedAvatarsView(avatars: replies, size: 20, border: 0)
//                        if let replies = attributedReplies {
//                            Text(replies)
//                                .font(.subheadline)
//                                .foregroundColor(Color.secondaryTxt)
//                        }
                        Text("unkown replies")
                        Spacer()
//                        Image.buttonReply
                    }
                    .padding(15)
                }
            case .golden:
                // TODO: add back when we add Discover screen
//                GoldenPostView(identifier: message.id, post: post, author: author)
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
            return EdgeInsets(top: 15, leading: 15, bottom: 0, trailing: 15)
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

//struct MessageCard_Previews: PreviewProvider {
//    static var messageValue: MessageValue {
//        MessageValue(
//            author: "@QW5uYVZlcnNlWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFg=.ed25519",
//            content: Content(
//                from: Post(
//                    blobs: nil,
//                    branches: nil,
//                    hashtags: nil,
//                    mentions: nil,
//                    root: nil,
//                    text: .loremIpsum(words: 10)
//                )
//            ),
//            hash: "",
//            previous: nil,
//            sequence: 0,
//            signature: .null,
//            claimedTimestamp: 0
//        )
//    }
//    static var message: Message {
//        var message = Message(
//            key: "@unset",
//            value: messageValue,
//            timestamp: 0
//        )
//        message.metadata = Message.Metadata(
//            author: Message.Metadata.Author(about: About(about: .null, name: "Mario")),
//            replies: Message.Metadata.Replies(count: 0, abouts: Set()),
//            isPrivate: false
//        )
//        return message
//    }
//
//    static var messageWithOneReply: Message {
//        var message = Message(
//            key: "@unset",
//            value: messageValue,
//            timestamp: 0
//        )
//        message.metadata = Message.Metadata(
//            author: Message.Metadata.Author(about: About(about: .null, name: "Mario")),
//            replies: Message.Metadata.Replies(
//                count: 1,
//                abouts: Set(Array(repeating: About(about: .null, image: .null), count: 1))
//            ),
//            isPrivate: false
//        )
//        return message
//    }
//
//    static var messageWithReplies: Message {
//        var message = Message(
//            key: "@unset",
//            value: messageValue,
//            timestamp: 0
//        )
//        message.metadata = Message.Metadata(
//            author: Message.Metadata.Author(about: About(about: .null, name: "Mario")),
//            replies: Message.Metadata.Replies(
//                count: 2,
//                abouts: Set(Array(repeating: About(about: .null, image: .null), count: 2))
//            ),
//            isPrivate: false
//        )
//        return message
//    }
//
//    static var messageWithLongAuthor: Message {
//        var message = Message(
//            key: "@unset",
//            value: messageValue,
//            timestamp: 0
//        )
//        message.metadata = Message.Metadata(
//            author: Message.Metadata.Author(about: About(about: .null, name: .loremIpsum(words: 8))),
//            replies: Message.Metadata.Replies(count: 0, abouts: Set()),
//            isPrivate: false
//        )
//        return message
//    }
//
//    static var messageWithUnknownAuthor: Message {
//        Message(
//            key: "@unset",
//            value: messageValue,
//            timestamp: 0
//        )
//    }
//
//    static var previews: some View {
//        Group {
//            ScrollView {
//                VStack {
//                    MessageCard(message: message)
//                    MessageCard(message: messageWithOneReply)
//                    MessageCard(message: messageWithReplies)
//                    MessageCard(message: messageWithLongAuthor)
//                    MessageCard(message: messageWithUnknownAuthor)
//                }
//            }
//            ScrollView {
//                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
//                    MessageCard(message: message, style: .golden)
//                    MessageCard(message: messageWithOneReply, style: .golden)
//                    MessageCard(message: messageWithReplies, style: .golden)
//                    MessageCard(message: messageWithLongAuthor, style: .golden)
//                    MessageCard(message: messageWithUnknownAuthor, style: .golden)
//                }
//            }
//            ScrollView {
//                VStack {
//                    MessageCard(message: message)
//                    MessageCard(message: messageWithOneReply)
//                    MessageCard(message: messageWithReplies)
//                    MessageCard(message: messageWithLongAuthor)
//                    MessageCard(message: messageWithUnknownAuthor)
//                }
//            }
//            .preferredColorScheme(.dark)
//        }
//        .padding()
//        .background(Color.appBg)
//        .environmentObject(BotRepository.fake)
//        .environmentObject(AppController.shared)
//    }
//}
