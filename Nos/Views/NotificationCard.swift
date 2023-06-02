//
//  NotificationsCard.swift
//  Nos
//
//  Created by Matthew Lorentz on 4/28/23.
//

import SwiftUI

struct NotificationCard: View {
    
    @ObservedObject private var note: Event
    private let user: Author
    private var actionText: AttributedString
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var relayService: RelayService
    
    @State private var attributedContent: AttributedString
    
    @State private var subscriptionIDs = [RelaySubscription.ID]()
    
    init(note: Event, user: Author) {
        self.note = note
        self.user = user
        
        var authorName = AttributedString("\(note.author?.safeName ?? Localized.someone.string) ")
        var range = Range(uncheckedBounds: (authorName.startIndex, authorName.endIndex))
        authorName[range].font = .boldSystemFont(ofSize: 17)
        
        if note.isReply(to: user) {
            actionText = authorName + AttributedString(Localized.Reply.repliedToYourNote.string)
        } else if note.references(author: user) {
            actionText = authorName + AttributedString(Localized.Reply.mentionedYou.string)
        } else {
            actionText = AttributedString()
        }
        
        range = Range(uncheckedBounds: (actionText.startIndex, actionText.endIndex))
        actionText[range].foregroundColor = .primaryTxt
        
        _attributedContent = .init(initialValue: AttributedString(note.content ?? ""))
    }
    
    var body: some View {
        if let author = note.author {
            Button {
                router.notificationsPath.append(note.referencedNote() ?? note)
            } label: {
                HStack {
                    AvatarView(imageUrl: author.profilePhotoURL, size: 40)
                        .shadow(radius: 10, y: 4)
                    
                    VStack {
                        HStack {
                            Text(actionText)
                                .lineLimit(1)
                            Spacer()
                        }
                        HStack {
                            Text("\"" + (attributedContent) + "\"")
                                .lineLimit(1)
                                .font(.body)
                                .foregroundColor(.primaryTxt)
                                .tint(.accent)
                            Spacer()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    if let elapsedTime = note.createdAt?.elapsedTimeFromNowString() {
                        VStack {
                            Spacer()
                            Text(elapsedTime)
                                .lineLimit(1)
                                .font(.body)
                                .foregroundColor(.secondaryText)
                        }
                    }
                }
                .padding(10)
                .background(
                    LinearGradient(
                        colors: [Color.cardBgTop, Color.cardBgBottom],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(20)
                .padding(.horizontal, 15)
            }
            .buttonStyle(CardButtonStyle())
            .onAppear {
                Task(priority: .userInitiated) {
                    let backgroundContext = PersistenceController.backgroundViewContext
                    await subscriptionIDs += Event.requestAuthorsMetadataIfNeeded(
                        noteID: note.identifier,
                        using: relayService,
                        in: backgroundContext
                    )
                }
            }
            .onDisappear {
                Task(priority: .userInitiated) {
                    await relayService.decrementSubscriptionCount(for: subscriptionIDs)
                    subscriptionIDs.removeAll()
                }
            }
            .task(priority: .userInitiated) {
                let backgroundContext = PersistenceController.backgroundViewContext
                if let parsedAttributedContent = await Event.attributedContent(
                    noteID: note.identifier,
                    context: backgroundContext
                ) {
                    withAnimation {
                        attributedContent = parsedAttributedContent
                    }
                }
            }
        }
    }
}
