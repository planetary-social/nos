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
                Image.iconOptions
                    // This hack fixes a weird issue where the confirmationDialog wouldn't be shown sometimes. ¯\_(ツ)_/¯
                    .background(showingOptions == true ? .clear : .clear)
                Image(systemName: "ellipsis")
            }
            .confirmationDialog(Localized.share.string, isPresented: $showingOptions) {
                Button(Localized.copyNoteIdentifier.string) {
                    // Analytics.shared.trackDidSelectAction(actionName: "copy_message_identifier")
                    copyMessageIdentifier()
                }
                // Button(Localized.shareThisMessage.text) {
                // Analytics.shared.trackDidSelectAction(actionName: "share_message")
                // showingShare = true
                // }
                // Button(Localized.viewSource.text) {
                // Analytics.shared.trackDidSelectAction(actionName: "view_message_source")
                // showingSource = true
                // }
                Button(Localized.reportPost.string, role: .destructive) {
                // Analytics.shared.trackDidSelectAction(actionName: "report_post")
                    reportPost()
                }
            }
            .sheet(isPresented: $showingSource) {
            }
            .sheet(isPresented: $showingShare) {
            }
        }
    }

    func copyMessageIdentifier() {
        let bech32NoteID = Bech32.encode(Nostr.notePrefix, baseEightData: Data(try! note.identifier!.bytes))
        UIPasteboard.general.string = bech32NoteID
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
