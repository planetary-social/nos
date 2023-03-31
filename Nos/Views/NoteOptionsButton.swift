//
//  NoteOptionsButton.swift
//  Nos
//
//  Created by Jason Cheatham on 3/6/23.
//

import Foundation
import SwiftUI
import secp256k1

struct NoteOptionsButton: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var currentUser: CurrentUser
    
    var note: Event

    @State
    private var showingOptions = false

    @State
    private var showingShare = false

    @State
    private var showingSource = false

    var body: some View {
        VStack {
            Button {
                showingOptions = true
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(.nosSecondary)
            }
            .confirmationDialog(Localized.share.string, isPresented: $showingOptions) {
                Button(Localized.copyNoteIdentifier.string) {
                    // Analytics.shared.trackDidSelectAction(actionName: "copy_message_identifier")
                    copyMessageIdentifier()
                }
                Button(Localized.copyNoteText.string) {
                    // Analytics.shared.trackDidSelectAction(actionName: "copy_message_text")
                    copyMessage()
                }
                Button(Localized.copyLink.string) {
                    // Analytics.shared.trackDidSelectAction(actionName: "copy_message_text")
                    copyLink()
                }
                // Button(Localized.shareThisMessage.text) {
                // Analytics.shared.trackDidSelectAction(actionName: "share_message")
                // showingShare = true
                // }
                // Button(Localized.viewSource.text) {
                // Analytics.shared.trackDidSelectAction(actionName: "view_message_source")
                // showingSource = true
                // }
                // Button(Localized.reportPost.string, role: .destructive) {
                // Analytics.shared.trackDidSelectAction(actionName: "report_post")
                //    reportPost()
                // }
                
                if note.author == currentUser.author {
                    Button(Localized.deleteNote.string) {
                        // Analytics.shared.trackDidSelectAction(actionName: "delete_message")
                        Task { await deletePost() }
                    }
                }
            }
            .sheet(isPresented: $showingSource) {
            }
            .sheet(isPresented: $showingShare) {
            }
        }
    }

    func copyMessageIdentifier() {
        UIPasteboard.general.string = note.bech32NoteID
    }
    
    func copyLink() {
        UIPasteboard.general.string = note.webLink
    }
    
    func copyMessage() {
        if let attrString = note.attributedContent(with: viewContext) {
            UIPasteboard.general.string = String(attrString.characters)
        }
    }
    
    func deletePost() async {
        if let identifier = note.identifier {
            await currentUser.publishDelete(for: [identifier])
        }
    }

    func reportPost() {
        // AppController.shared.report(message, in: nil, from: message.author)
    }
}

struct NoteOptionsView_Previews: PreviewProvider {
    static var persistenceController = PersistenceController.preview
    static var previewContext = persistenceController.container.viewContext
    
    static var shortNote: Event {
        let note = Event(context: previewContext)
        note.content = "Hello, world!"
        return note
    }
    
    static let note: Event = {
        var note = shortNote
        return note
    }()

    static var previews: some View {
        Group {
            NoteOptionsButton(note: note)
            NoteOptionsButton(note: note)
                .preferredColorScheme(.dark)
        }
        .padding()
        .background(Color.cardBackground)
    }
}
