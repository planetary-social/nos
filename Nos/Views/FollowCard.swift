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

    @EnvironmentObject private var router: Router

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
                            Text(Localized.mutedUser.string)
                                .font(.subheadline)
                                .foregroundColor(Color.secondaryTxt)
                        }
                        Spacer()
                        if let currentUser = CurrentUser.shared.author {
                            FollowButton(currentUserAuthor: currentUser, author: author)
                                .padding(10)
                        }
                    }
                }
                // TODO: Put MessageOptionsButton back here eventually
            }
            .padding(10)
            Divider().overlay(Color.cardDivider).shadow(color: .cardDividerShadow, radius: 0, x: 0, y: 1)
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
