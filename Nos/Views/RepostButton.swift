//
//  RepostButton.swift
//  Nos
//
//  Created by Matthew Lorentz on 4/21/23.
//

import SwiftUI
import SwiftUINavigation
import Logger

struct RepostButton: View {
    
    var note: Event
    
    @FetchRequest private var reposts: FetchedResults<Event>
    @EnvironmentObject private var relayService: RelayService
    @Environment(CurrentUser.self) private var currentUser
    @Environment(\.managedObjectContext) private var viewContext
    
    /// We use this to give instant feedback when the button is tapped, even though the action it performs is async.
    @State private var tapped = false
    @State private var shouldConfirmRepost = false
    @State private var shouldConfirmDelete = false
    
    internal init(note: Event) {
        self.note = note
        _reposts = FetchRequest(fetchRequest: Event.reposts(noteID: note.identifier ?? ""))
    }
    
    var currentUserRepostedNote: Bool {
        reposts.contains {
            $0.author?.hexadecimalPublicKey == currentUser.author?.hexadecimalPublicKey
        }
    }

    var body: some View {
        Button { 
            Task {
                await buttonPressed()
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
        .disabled(tapped)
        .confirmationDialog(String(localized: .localizable.repost), isPresented: $shouldConfirmRepost) {
            Button(String(localized: .localizable.repost)) {
                Task { await repostNote() }
            }
            Button(String(localized: .localizable.cancel), role: .cancel) {
                tapped = false
            }
        }
        .confirmationDialog(String(localized: .localizable.deleteRepost), isPresented: $shouldConfirmDelete) {
            Button(String(localized: .localizable.deleteRepost), role: .destructive) {
                Task { await deleteReposts() }
            }
        }
    }
    
    func buttonPressed() async {
        if !tapped && !currentUserRepostedNote {
            tapped = true
            shouldConfirmRepost = true
        } else if !tapped && currentUserRepostedNote {
            shouldConfirmDelete = true
        } else {
            // The repost is currently being published, don't do anything.
        }
    }
    
    func repostNote() async {
        defer { tapped = false }
        guard let keyPair = currentUser.keyPair else {
            return
        }
        
        var tags: [[String]] = []
        if let id = note.identifier {
            tags.append(["e", id] + note.seenOnRelayURLs)
        }
        if let pubKey = note.author?.publicKey?.hex {
            tags.append(["p", pubKey])
        }
        
        let jsonEvent = JSONEvent(
            pubKey: keyPair.publicKeyHex,
            kind: .repost,
            tags: tags,
            content: note.jsonString ?? ""
        )
        
        do {
            try await relayService.publishToAll(event: jsonEvent, signingKey: keyPair, context: viewContext)
        } catch {
            Log.error(error, "Error creating event for repost")
        }
    }
    
    func deleteReposts() async {
        reposts
            .filter {
                $0.author?.hexadecimalPublicKey == currentUser.author?.hexadecimalPublicKey
            }
            .compactMap { $0.identifier }
            .forEach { noteIdentifier in
                Task {
                    await currentUser.publishDelete(for: [noteIdentifier])
                }
            }
    }
}
