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
    @EnvironmentObject private var currentUser: CurrentUser

    @State private var subscriptionId: String = ""
    
    @State private var nip05Identifier: String = ""
    @State private var verifiedNip05Identifier: Bool?
    
    var followsRequest: FetchRequest<Follow>
    var followsResult: FetchedResults<Follow> { followsRequest.wrappedValue }

    var followersRequest: FetchRequest<Follow>
    var followersResult: FetchedResults<Follow> { followersRequest.wrappedValue }
    
    var follows: Followed {
        followsResult.map { $0 }
    }

    var followers: Followed {
        followersResult.map { $0 }
    }
    
    @EnvironmentObject private var router: Router
    
    init(author: Author) {
        self.author = author
        self.followsRequest = FetchRequest(fetchRequest: Follow.followsRequest(sources: [author]))
        self.followersRequest = FetchRequest(fetchRequest: Follow.followsRequest(destination: [author]))
    }

    private var shouldShowBio: Bool {
        if let about = author.about {
            return about.isEmpty == false
        }
        return false
    }

    private var knownFollowers: [Follow] {
        author.followers.filter {
            guard let source = $0.source else {
                return false
            }
            return source.hasHumanFriendlyName == true &&
                source != author &&
                (currentUser.isFollowing(author: source) || currentUser.isBeingFollowedBy(author: source))
        }
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

                        PlainText(author.safeName)
                            .lineLimit(1)
                            .font(.clarityTitle3.weight(.semibold))
                            .foregroundColor(Color.primaryTxt)
                        
                        if !(author.uns ?? "").isEmpty {
                            Button {
                                if let url = relayService.unsURL(from: author.uns ?? "") {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                PlainText("\(author.uns ?? "")@universalname.space")
                                    .foregroundColor(.secondaryText)
                                    .font(.claritySubheadline)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                        
                        if let nip05Identifier = author.nip05, !nip05Identifier.isEmpty {
                            Button {
                                let domain = relayService.domain(from: nip05Identifier)
                                let urlString = "https://\(domain)"
                                guard let url = URL(string: urlString) else { return }
                                UIApplication.shared.open(url)
                            } label: {
                                Group {
                                    if verifiedNip05Identifier == true {
                                        PlainText("\(relayService.identifierToShow(nip05Identifier))")
                                            .foregroundColor(.primaryTxt)
                                    } else if verifiedNip05Identifier == false {
                                        PlainText(nip05Identifier)
                                            .strikethrough()
                                            .foregroundColor(.secondaryText)
                                    } else {
                                        PlainText("\(relayService.identifierToShow(nip05Identifier))")
                                            .foregroundColor(.secondaryText)
                                    }
                                }
                                .font(.claritySubheadline)
                                .multilineTextAlignment(.leading)
                            }
                            .padding(.top, 3)
                        }

                        if author != currentUser.author, let currentUser = currentUser.author {
                            HStack {
                                FollowButton(currentUserAuthor: currentUser, author: author)
                                if author.muted {
                                    Text(Localized.muted.string)
                                        .font(.subheadline)
                                        .foregroundColor(Color.secondaryText)
                                }
                            }
                            .padding(.top, 3)
                        }

                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top)
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .topLeading)

                if shouldShowBio {
                    BioView(bio: author.about)
                }

                if let first = knownFollowers[safe: 0]?.source {
                    Button {
                        router.currentPath.wrappedValue.append(
                            FollowersDestination(
                                author: author,
                                followers: followersResult.compactMap { $0.source }
                            )
                        )
                    } label: {
                        ProfileKnownFollowersView(
                            first: first,
                            knownFollowers: knownFollowers,
                            followers: followers
                        )
                    }
                }

                ProfileSocialStatsView(
                    author: author,
                    followsResult: followsResult,
                    followersResult: followersResult
                )
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
        .task(priority: .userInitiated) {
            if let nip05Identifier = author.nip05,
                let publicKey = author.publicKey?.hex {
                let verifiedNip05Identifier = await relayService.verifyNIP05(
                    identifier: nip05Identifier,
                    userPublicKey: publicKey
                )
                withAnimation {
                    self.verifiedNip05Identifier = verifiedNip05Identifier
                }
            }
        }
        .onDisappear {
            Task(priority: .userInitiated) {
                await relayService.decrementSubscriptionCount(for: subscriptionId)
                subscriptionId = ""
            }
        }
    }
}

struct IdentityHeaderView_Previews: PreviewProvider {

    static var previewData = PreviewData()
    static var persistenceController = PersistenceController.preview
    static var previewContext = persistenceController.container.viewContext
    static var relayService = previewData.relayService
    static var currentUser = previewData.currentUser
    
    static var author: Author {
        let author = Author(context: previewContext)
        author.hexadecimalPublicKey = KeyFixture.pubKeyHex
        author.add(relay: Relay(context: previewContext))
        author.name = "Sebastian Heit"
        author.nip05 = "chardot@nostr.fan"
        // author.uns = "chardot"
        author.about = "Go programmer working on Nos/Planetary. You can find me at various European events related to" +
        " Chaos Computer Club, the hacker community and free software."
        let first = Author(context: previewContext)
        first.name = "Craig Nichols"

        let second = Author(context: previewContext)
        second.name = "Justin Pool"

        let firstFollow = Follow(context: previewContext)
        firstFollow.source = first
        firstFollow.destination = author

        let secondFollow = Follow(context: previewContext)
        secondFollow.source = second
        secondFollow.destination = author

        author.addToFollowers(secondFollow)

        return author
    }
    
    static var previews: some View {
        Group {
            // ProfileHeader(author: author)
            ProfileHeader(author: author).preferredColorScheme(.light)
        }
        .environmentObject(relayService)
        .environmentObject(currentUser)
        .previewDevice("iPhone SE (2nd generation)")
        .padding()
        .background(Color.cardBackground)
    }
}
