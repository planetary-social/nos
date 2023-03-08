//
//  Notebutton.swift
//  Nos
//
//  Created by Jason Cheatham on 2/16/23.
//

import Foundation
import SwiftUI

/// This view displays the a button with the information we have for a note suitable for being used in a list
/// or grid.
///
/// The button opens the ThreadView for the note when tapped.
struct NoteButton: View {
    var note: Event
    var style = CardStyle.compact

    @EnvironmentObject private var router: Router
    @EnvironmentObject private var relayService: RelayService

    var body: some View {
        if let author = note.author, !author.muted {
            Button {
                // If we are on the home feed or this is not the root note, allow clicks on replies
                if router.path.count == 0 || note.eventReferences?.count ?? 0 > 0
                    || router.navigationTitle == Localized.profile.rawValue {
                    router.path.append(note)
                }
            } label: {
                NoteCard(author: author, note: note, style: style)
            }
            .buttonStyle(CardButtonStyle())
        }
    }
}

struct NoteButton_Previews: PreviewProvider {
   
    static var persistenceController = PersistenceController.preview
    static var previewContext = persistenceController.container.viewContext
    static var router = Router()
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
            NoteButton(note: shortNote)
            NoteButton(note: shortNote, style: .golden)
            NoteButton(note: longNote)
                .preferredColorScheme(.dark)
        }
        .environmentObject(router)
    }
}
