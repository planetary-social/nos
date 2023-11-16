//
//  FollowCard.swift
//  Nos
//
//  Created by Christopher Jorgensen on 2/22/23.
//

import SwiftUI

/// This view displays the information we have for an message suitable for being used in a list or grid.
///
/// Use this view inside MessageButton to have nice borders.
struct FollowCard: View {

    @ObservedObject var author: Author
    
    @Environment(\.managedObjectContext) private var viewContext
   
    var style = CardStyle.compact

    @Environment(Router.self) private var router
    @Environment(CurrentUser.self) private var currentUser
    @EnvironmentObject private var relayService: RelayService
    
    @State private var subscriptions = [RelaySubscription.ID]()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                Button {
                    router.currentPath.wrappedValue.append(author)
                } label: {
                    HStack(alignment: .center) {
                        AvatarView(imageUrl: author.profilePhotoURL, size: 24)
                        Text(author.safeName)
                            .lineLimit(1)
                            .font(.subheadline)
                            .foregroundColor(Color.primaryTxt)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if author.muted {
                            Text(Localized.muted.string)
                                .font(.subheadline)
                                .foregroundColor(Color.secondaryText)
                        }
                        Spacer()
                        if let currentUser = currentUser.author {
                            FollowButton(currentUserAuthor: currentUser, author: author)
                                .padding(10)
                        }
                    }
                }
                // TODO: Put MessageOptionsButton back here eventually
            }
            .padding(10)
            BeveledSeparator()
        }
        .background(
            LinearGradient(
                colors: [Color.cardBgTop, Color.cardBgBottom],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .listRowInsets(EdgeInsets())
        .cornerRadius(cornerRadius)
        .onAppear {
            Task(priority: .userInitiated) { 
                let subscriptionIDs = await relayService.requestMetadata(
                    for: author.hexadecimalPublicKey, 
                    since: author.lastUpdatedMetadata
                ) 
                subscriptions.append(contentsOf: subscriptionIDs) 
            }
        }
        .onDisappear {
            subscriptions.forEach { subscriptionID in
                Task { await relayService.decrementSubscriptionCount(for: subscriptionID) }
            }
        }
    }

    var cornerRadius: CGFloat {
        switch style {
        case .golden:
            return 15
        case .compact:
            return 15
        }
    }
}
