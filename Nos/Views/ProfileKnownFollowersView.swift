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
                    Text(Localized.followedByTwoAndMore.localizedMarkdown([
                        "one": first.safeName,
                        "two": second.safeName,
                        "count": "\(followers.count - 2)"
                    ]))
                } else {
                    Text(Localized.followedByTwo.localizedMarkdown([
                        "one": first.safeName,
                        "two": second.safeName
                    ]))
                }
            } else {
                StackedAvatarsView(avatarUrls: [first.profilePhotoURL])
                if followers.count > 1 {
                    Text(Localized.followedByOneAndMore.localizedMarkdown([
                        "one": first.safeName,
                        "count": "\(followers.count - 1)"
                    ]))
                } else {
                    Text(Localized.followedByOne.localizedMarkdown([
                        "one": first.safeName
                    ]))
                }
            }
        }
        .font(.subheadline)
        .padding(EdgeInsets(top: 0, leading: 18, bottom: 0, trailing: 18))
        .multilineTextAlignment(.leading)
    }
}
