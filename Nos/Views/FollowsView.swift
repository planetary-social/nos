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

    func author(id: String) -> Author {
        try! Author.findOrCreate(by: id, context: viewContext)
    }
    
    var body: some View {
        ScrollView(.vertical) {
            LazyVStack {
                ForEach(followed) { follow in
                    VStack {
                        FollowCard(author: follow.destination!)
                    }
                    .onAppear {
                        if let author = follow.destination, !author.isPopulated, let key = author.hexadecimalPublicKey {
                            print("📡Need to sync author: \(key)")
                            let filter = Filter(authorKeys: [key], kinds: [.metaData, .contactList], limit: 103)
                            relayService.requestEventsFromAll(filter: filter)
                        }
                    }
                    Spacer()
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            router.navigationTitle = "Follows"
        }
    }
}
