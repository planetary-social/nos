//
//  FollowsView.swift
//  Nos
//
//  Created by Christopher Jorgensen on 2/22/23.
//

import Foundation
import SwiftUI

struct FollowsDestination: Hashable {
    var author: Author
    var follows: [Author]
}

struct FollowersDestination: Hashable {
    var author: Author
    var followers: [Author]
}

/// Displays a list of people someone is following.
struct FollowsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var relayService: RelayService
    @EnvironmentObject var router: Router

    /// Screen title
    var title: Localized

    /// Sorted list of authors to display in the list
    var authors: [Author]
    
    @State private var subscriptionId: String = ""
    
    func refreshFollows() {
        Task(priority: .userInitiated) {
            // TODO: just grab metadata for people who need it, not a random 100
            let keys = authors.compactMap { $0.hexadecimalPublicKey }
            let filter = Filter(authorKeys: keys, kinds: [.metaData, .contactList], limit: 100)
            subscriptionId = await relayService.openSubscription(with: filter)
        }
    }
    
    var body: some View {
        ScrollView(.vertical) {
            LazyVStack {
                ForEach(authors) { author in
                    FollowCard(author: author)
                        .padding(.horizontal)
                        .readabilityPadding()
                }
            }
            .padding(.top)
        }
        .background(Color.appBg)
        .nosNavigationBar(title: title)
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
