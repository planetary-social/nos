//
//  AuthorCardKnowFollowersView.swift
//  Nos
//
//  Created by Rabble on 10/10/23.
//

import Foundation
import SwiftUI

struct AuthorCardKnownFollowersView: View {
    var first: Author
    var knownFollowers: [Follow]
    var followers: [Follow]

    var body: some View {
        VStack {
            if let second = knownFollowers[safe: 1]?.source {
                if followers.count > 2 {
                    Text(Localized.followedByTwoAndMore.localizedMarkdown([
                        "one": first.safeName,
                        "two": second.safeName,
                        "count": "\(followers.count - 2)"
                    ])).fixedSize(horizontal: false, vertical: true)
                } else {
                    Text(Localized.followedByTwo.localizedMarkdown([
                        "one": first.safeName,
                        "two": second.safeName
                    ])).fixedSize(horizontal: false, vertical: true)
                }
                HStack {
                    StackedAvatarsView(avatarUrls: [first.profilePhotoURL, second.profilePhotoURL])
                    Spacer()
                }
            } else {
                if followers.count > 1 {
                    Text(Localized.followedByOneAndMore.localizedMarkdown([
                        "one": first.safeName,
                        "count": "\(followers.count - 1)"
                    ])).fixedSize(horizontal: false, vertical: true)
                } else {
                    Text(Localized.followedByOne.localizedMarkdown([
                        "one": first.safeName
                    ])).fixedSize(horizontal: false, vertical: true)
                }
                HStack {
                    StackedAvatarsView(avatarUrls: [first.profilePhotoURL])
                    Spacer()
                }
            }
        }
        .font(.clarityFootnote)
        .padding(EdgeInsets(top: 0, leading: 18, bottom: 0, trailing: 18))
        .multilineTextAlignment(.leading)
    }
}
