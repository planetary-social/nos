//
//  FollowButton.swift
//  Nos
//
//  Created by Christopher Jorgensen on 2/24/23.
//

import SwiftUI
import Dependencies

struct FollowButton: View {
    @ObservedObject var currentUserAuthor: Author
    @ObservedObject var author: Author
    @Environment(\.managedObjectContext) private var viewContext
    @Dependency(\.analytics) private var analytics
    
    var body: some View {
        let following = CurrentUser.isFollowing(author: author)
        Button {
            if following {
                CurrentUser.unfollow(author: author, context: viewContext)
                analytics.unfollowed(author)
            } else {
                CurrentUser.follow(author: author, context: viewContext)
                analytics.followed(author)
            }
        } label: {
            Text(following ? Localized.unfollow.string : Localized.follow.string)
        }
    }
}
