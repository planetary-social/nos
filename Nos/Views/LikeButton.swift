//
//  LikeButton.swift
//  Nos
//
//  Created by Matthew Lorentz on 4/21/23.
//

import SwiftUI

struct LikeButton: View {
    
    var note: Event
    var action: () async -> Void
    @FetchRequest private var likes: FetchedResults<Event>
    @EnvironmentObject private var currentUser: CurrentUser
    /// We use this to give instant feedback when the button is tapped, even though the action it performs is async.
    @State private var tapped = false
    
    internal init(note: Event, action: @escaping () async -> Void) {
        self.note = note
        self.action = action
        _likes = FetchRequest(fetchRequest: Event.likes(noteID: note.identifier!))
    }
    
    var likeCount: Int {
        likes
            .compactMap { $0.eventReferences?.lastObject as? EventReference }
            .map { $0.eventId }
            .filter { $0 == note.identifier }
            .count
    }
      
    var currentUserLikesNote: Bool {
        likes
            .filter {
                $0.author?.hexadecimalPublicKey == currentUser.author?.hexadecimalPublicKey
            }
            .compactMap { $0.eventReferences?.lastObject as? EventReference }
            .contains(where: { $0.eventId == note.identifier })
    }
    
    var buttonLabel: some View {
        HStack {
            if currentUserLikesNote || tapped {
                Image.buttonLikeActive
            } else {
                Image.buttonLikeDefault
            }
            if likeCount > 0 {
                Text(likeCount.description)
                    .font(.body)
                    .foregroundColor(.secondaryTxt)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 12)
    }
    
    var body: some View {
        Button {
            tapped = true
            Task {
                await action()
            }
        } label: {
            buttonLabel
        }                             
        .disabled(currentUserLikesNote || tapped)
    }
}
