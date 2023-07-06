//
//  FollowsView.swift
//  Nos
//
//  Created by Christopher Jorgensen on 2/22/23.
//

import Foundation
import SwiftUI

/// Displays a list of people someone is following.
struct FollowsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var relayService: RelayService
    @EnvironmentObject var router: Router
    
    var followed: Followed
    
    @State private var subscriptionId: String = ""
    
    func refreshFollows() {
        Task(priority: .userInitiated) {
            // TODO: just grab metadata for people who need it, not a random 100
            let keys = followed.compactMap { $0.destination?.hexadecimalPublicKey }
            let filter = Filter(authorKeys: keys, kinds: [.metaData, .contactList], limit: 100)
            subscriptionId = await relayService.openSubscription(with: filter)
        }
    }
    
    var body: some View {
        ScrollView(.vertical) {
            LazyVStack {
                ForEach(followed) { follow in
                    if let author = follow.destination {
                        FollowCard(author: author)
                            .padding(.horizontal)
                            .readabilityPadding()
                    }
                }
            }
            .padding(.top)
        }
        .background(Color.appBg)
        .nosNavigationBar(title: .follows)
        .task(priority: .userInitiated) {
            refreshFollows()
        }
        .onDisappear {
            Task(priority: .userInitiated) {
                await relayService.decrementSubscriptionCount(for: subscriptionId)
                subscriptionId = ""
            }
        }
    }
}
