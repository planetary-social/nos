//
//  FollowButton.swift
//  Nos
//
//  Created by Christopher Jorgensen on 2/24/23.
//

import SwiftUI

struct FollowButton: View {
    @ObservedObject var currentUserAuthor: Author
    @ObservedObject var author: Author
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        Button {
            if CurrentUser.isFollowing(author: author) {
                CurrentUser.unfollow(author: author, context: viewContext)
            } else {
                CurrentUser.follow(author: author, context: viewContext)
            }
        } label: {
            Text(CurrentUser.isFollowing(author: author) ? Localized.unfollow.string : Localized.follow.string)
        }
    }
}
