//
//  RepostButton.swift
//  Nos
//
//  Created by Matthew Lorentz on 4/21/23.
//

import SwiftUI

struct RepostButton: View {
    
    var note: Event
    var action: () async -> Void
    @FetchRequest private var reposts: FetchedResults<Event>
    @EnvironmentObject private var currentUser: CurrentUser
    /// We use this to give instant feedback when the button is tapped, even though the action it performs is async.
    @State private var tapped = false
    
    internal init(note: Event, action: @escaping () async -> Void) {
        self.note = note
        self.action = action
        _reposts = FetchRequest(fetchRequest: Event.reposts(noteID: note.identifier!))
    }
    
    var currentUserRepostedNote: Bool {
        reposts.contains {
            $0.author?.hexadecimalPublicKey == currentUser.author?.hexadecimalPublicKey
        }
    }

    var body: some View {
        Button { 
            tapped = true
            Task {
                await action()
            }
        } label: {
            HStack {
                if currentUserRepostedNote || tapped {
                    Image.repostButtonPressed
                } else {
                    Image.repostButton
                }
                
                if reposts.count > 0 {
                    Text(reposts.count.description)
                        .font(.body)
                        .foregroundColor(.secondaryTxt)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 12)
        }
        .disabled(currentUserRepostedNote || tapped)
    }
}
