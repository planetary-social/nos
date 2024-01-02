//
//  MutesView.swift
//  Nos
//
//  Created by Martin Dutra on 7/7/23.
//

import SwiftUI

struct MutesDestination: Hashable { }

struct MutesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var relayService: RelayService
    @EnvironmentObject private var router: Router

    @FetchRequest
    private var authors: FetchedResults<Author>

    init() {
        _authors = FetchRequest(fetchRequest: Author.allAuthorsRequest(muted: true))
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
        .nosNavigationBar(title: .localizable.mutedUsers)
    }
}

struct MutesView_Previews: PreviewProvider {
    static var previews: some View {
        MutesView()
    }
}
