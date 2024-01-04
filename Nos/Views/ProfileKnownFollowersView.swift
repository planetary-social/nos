//
//  ProfileKnownFollowersView.swift
//  Nos
//
//  Created by Martin Dutra on 9/8/23.
//

import SwiftUI

struct ProfileKnownFollowersView: View {
    var first: Author
    var knownFollowers: [Follow]
    var followers: [Follow]

    var body: some View {
        HStack {
            if let second = knownFollowers[safe: 1]?.source {
                StackedAvatarsView(avatarUrls: [first.profilePhotoURL, second.profilePhotoURL])
                if followers.count > 2 {
                    Text(.localizable.followedByTwoAndMore(first.safeName, second.safeName, followers.count - 2))
                } else {
                    Text(.localizable.followedByTwo(first.safeName, second.safeName))
                }
            } else {
                StackedAvatarsView(avatarUrls: [first.profilePhotoURL])
                if followers.count > 1 {
                    Text(.localizable.followedByOneAndMore(first.safeName, followers.count - 1))
                } else {
                    Text(.localizable.followedByOne(first.safeName))
                }
            }
        }
        .font(.subheadline)
        .padding(EdgeInsets(top: 0, leading: 18, bottom: 0, trailing: 18))
        .multilineTextAlignment(.leading)
    }
}
