//
//  IdentityViewHeader.swift
//  Planetary
//
//  Created by Martin Dutra on 11/11/22.
//  Copyright © 2022 Verse Communications Inc. All rights reserved.
//

import SwiftUI
import CoreData

struct ProfileHeader: View {
    @ObservedObject var author: Author
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var relayService: RelayService

    @State private var subscriptionId: String = ""

    var followsRequest: FetchRequest<Follow>
    var followsResult: FetchedResults<Follow> { followsRequest.wrappedValue }
    
    var follows: Followed {
        followsResult.map { $0 }
    }
    
    @EnvironmentObject private var router: Router
    
    init(author: Author) {
        self.author = author
        self.followsRequest = FetchRequest(fetchRequest: Follow.followsRequest(sources: [author]))
    }
    
    func refreshFollows() {
        if let follows = author.follows?.allObjects as? [Follow] {
            let keys = follows.compactMap { $0.destination?.hexadecimalPublicKey }
            let filter = Filter(authorKeys: keys, kinds: [.metaData, .contactList], limit: 100)
            subscriptionId = relayService.requestEventsFromAll(filter: filter)
        }
    }

    private var shouldShowBio: Bool {
        if let about = author.about {
            return about.isEmpty == false
        }
        return false
    }

    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                HStack(alignment: .top, spacing: 18) {
                    ZStack(alignment: .bottomTrailing) {
                        AvatarView(imageUrl: author.profilePhotoURL, size: 87)
                            .font(.body)
                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 99)
                                    .stroke(LinearGradient.diagonalAccent, lineWidth: 3)
                            )
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Spacer()
                        HStack {
                            Text(author.safeName)
                                .lineLimit(1)
                                .font(.title3.weight(.semibold))
                                .foregroundColor(Color.primaryTxt)
                            Spacer()
                            FollowButton(currentUserAuthor: CurrentUser.author, author: author)
                        }
                        Spacer()

                        Button {
                            router.path.append(follows)
                        } label: {
                            Text("\(Localized.following.string): \(author.follows?.count ?? 0)")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding()
                .frame(maxWidth: .infinity, alignment: .topLeading)
                if shouldShowBio {
                    BioView(bio: author.about)
                }
            }
            .frame(maxWidth: 500)
        }
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color.profileBgTop, Color.profileBgBottom],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .navigationDestination(for: Followed.self) { followed in
            FollowsView(followed: followed)
        }
        .task {
            refreshFollows()
        }
        .onDisappear {
            relayService.sendCloseToAll(subscriptions: [subscriptionId])
            subscriptionId = ""
        }
    }
}

// swiftlint:disable force_unwrapping
struct IdentityHeaderView_Previews: PreviewProvider {
    
    static var persistenceController = PersistenceController.preview
    static var previewContext = persistenceController.container.viewContext
    
    static var author: Author {
        let author = Author(context: previewContext)
        author.hexadecimalPublicKey = KeyFixture.pubKeyHex
        return author
    }
    
    static var previews: some View {
        Group {
            ProfileHeader(author: author)
        }
        .padding()
        .background(Color.cardBackground)
    }
}
