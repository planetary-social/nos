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
    var showReplyCount = true
    private let replyAction: ((Event) -> Void)?
    private let tapAction: ((Event) -> Void)?

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
        showReplyCount: Bool = true, 
        replyAction: ((Event) -> Void)? = nil,
        tapAction: ((Event) -> Void)? = nil
    ) {
        self.note = note
        self.style = style
        self.showFullMessage = showFullMessage
        self.hideOutOfNetwork = hideOutOfNetwork
        self.showReplyCount = showReplyCount
        self.replyAction = replyAction
        self.tapAction = tapAction
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
            if note.kind == EventKind.repost.rawValue, let author = note.author {
                let repost = note
                Button(action: { 
                    router.push(author)
                }, label: { 
                    HStack(alignment: .center) {
                        AuthorLabel(author: author)
                        Image.repostSymbol
                        if let elapsedTime = repost.createdAt?.elapsedTimeFromNowString() {
                            Text(elapsedTime)
                                .lineLimit(1)
                                .font(.body)
                                .foregroundColor(.secondaryText)
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
                            await relayService.decrementSubscriptionCount(for: subscriptionIDs)
                            subscriptionIDs.removeAll()
                        }
                    }
                })
            }
            
            Button {
                if let tapAction {
                    tapAction(displayedNote)
                } else {
                    if let referencedNote = displayedNote.referencedNote() {
                        router.push(referencedNote)
                    } else {
                        router.push(displayedNote)
                    }
                }
            } label: {
                let noteCard = NoteCard(
                    note: displayedNote,
                    style: style,
                    showFullMessage: showFullMessage,
                    hideOutOfNetwork: hideOutOfNetwork,
                    showReplyCount: showReplyCount,
                    replyAction: replyAction
                )
                
                switch style {
                case .compact:
                    noteCard
                        .padding(.horizontal)
                        .readabilityPadding()
                case .golden:
                    noteCard
                }
            }
            .buttonStyle(CardButtonStyle())
        }
    }
}

struct NoteButton_Previews: PreviewProvider {
    
    static var previews: some View {
        VStack {
            NoteButton(note: PreviewData.repost, hideOutOfNetwork: false)
            NoteButton(note: PreviewData.shortNote)
            NoteButton(note: PreviewData.shortNote, style: .golden)
            NoteButton(note: PreviewData.longNote)
        }
        .environment(\.managedObjectContext, PreviewData.previewContext)
        .environmentObject(PreviewData.relayService)
        .environmentObject(PreviewData.router)
        .environmentObject(PreviewData.currentUser)
    }
}
