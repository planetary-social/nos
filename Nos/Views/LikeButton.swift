//
//  LikeButton.swift
//  Nos
//
//  Created by Matthew Lorentz on 4/21/23.
//

import Dependencies
import Logger
import SwiftUI

struct LikeButton: View {
    
    var note: Event
    @FetchRequest private var likes: FetchedResults<Event>
    /// We use this to give instant feedback when the button is tapped, even though the action it performs is async.
    @State private var tapped = false
    @EnvironmentObject private var relayService: RelayService
    @Environment(CurrentUser.self) private var currentUser
    @Environment(\.managedObjectContext) private var viewContext
    @ObservationIgnored @Dependency(\.analytics) private var analytics

    internal init(note: Event) {
        self.note = note
        if let noteID = note.identifier {
            _likes = FetchRequest(fetchRequest: Event.likes(noteID: noteID))
        } else {
            _likes = FetchRequest(fetchRequest: Event.emptyRequest())
        }
    }
    
    var likeCount: Int {
        likes
            .compactMap { $0.eventReferences.lastObject as? EventReference }
            .map { $0.eventId }
            .filter { $0 == note.identifier }
            .count
    }
      
    var currentUserLikesNote: Bool {
        likes
            .filter {
                $0.author?.hexadecimalPublicKey == currentUser.author?.hexadecimalPublicKey
            }
            .compactMap { $0.eventReferences.lastObject as? EventReference }
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
                    .foregroundColor(.secondaryText)
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
    
    private func action() async {

        guard let keyPair = currentUser.keyPair else {
            return
        }

        var tags: [[String]] = []
        if let eventReferences = note.eventReferences.array as? [EventReference] {
            // compactMap returns an array of the non-nil results.
            tags += eventReferences.compactMap { event in
                guard let eventId = event.eventId else { return nil }
                return ["e", eventId]
            }
        }

        if let authorReferences = note.authorReferences.array as? [EventReference] {
            tags += authorReferences.compactMap { author in
                guard let eventId = author.eventId else { return nil }
                return ["p", eventId]
            }
        }

        if let id = note.identifier {
            tags.append(["e", id] + note.seenOnRelayURLs)
        }
        if let pubKey = note.author?.publicKey?.hex {
            tags.append(["p", pubKey])
        }

        let jsonEvent = JSONEvent(
            pubKey: keyPair.publicKeyHex,
            kind: .like,
            tags: tags,
            content: "+"
        )

        do {
            try await relayService.publishToAll(event: jsonEvent, signingKey: keyPair, context: viewContext)
            analytics.likedNote()
        } catch {
            Log.info("Error creating event for like")
        }
    }
}
