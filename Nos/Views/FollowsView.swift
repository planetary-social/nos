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
    @EnvironmentObject var router: Router
    
    var followed: Followed
    
    @State private var subscriptionId: String = ""
    
    func refreshFollows() {
        let keys = followed.compactMap { $0.destination?.hexadecimalPublicKey }
        let filter = Filter(authorKeys: keys, kinds: [.metaData, .contactList], limit: 100)
        subscriptionId = relayService.openSubscription(with: filter)
    }
    
    var body: some View {
        ScrollView(.vertical) {
            LazyVStack {
                ForEach(followed) { follow in
                    if let author = follow.destination {
                        FollowCard(author: author)
                            .padding(.horizontal)
                    }
                }
            }
            .padding(.top)
        }
        .background(Color.appBg)
        .nosNavigationBar(title: .follows)
        .task {
            refreshFollows()
        }
        .onDisappear {
            relayService.removeSubscription(for: subscriptionId)
            subscriptionId = ""
        }
    }
}
