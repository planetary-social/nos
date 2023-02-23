//
//  FollowsView.swift
//  Nos
//
//  Created by Christopher Jorgensen on 2/22/23.
//

import Foundation
import SwiftUI

// This could be used both for followed and followers
struct FollowsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var relayService: RelayService

    var followed: Followed
    let syncTimer = SyncTimer()

    @State private var authorsToSync: [Author] = []

    func author(id: String) -> Author {
        try! Author.findOrCreate(by: id, context: viewContext)
    }
    
    var body: some View {
        ScrollView(.vertical) {
            LazyVStack {
                ForEach(followed) { tag in
                    VStack {
                        // TODO: This needs to be its own view with an author state var
                        FollowCard(author: author(id: tag.identifier!))
                    }
                    .onAppear {
                        // Error scenario: we have an event in core data without an author
                        let author = author(id: tag.identifier!)
                        
                        if !author.isPopulated {
                            print("Need to sync author: \(author.hexadecimalPublicKey ?? "")")
                            authorsToSync.append(author)
                        }
                    }
                    Spacer()
                }
            }
        }
        .onReceive(syncTimer.currentTimePublisher) { _ in
            if !authorsToSync.isEmpty {
                print("Syncing \(authorsToSync.count) authors")
                let authorKeys = authorsToSync.map({ $0.hexadecimalPublicKey! })
                let filter = Filter(authorKeys: authorKeys, kinds: [.metaData], limit: authorsToSync.count)
                relayService.requestEventsFromAll(filter: filter)
                authorsToSync.removeAll()
            }
        }
    }
}
