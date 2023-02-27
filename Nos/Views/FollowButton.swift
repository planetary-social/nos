//
//  FollowButton.swift
//  Nos
//
//  Created by Christopher Jorgensen on 2/24/23.
//

import SwiftUI

struct FollowButton: View {
    @ObservedObject var author: Author
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        let isFollowing = CurrentUser.isFollowing(key: author.hexadecimalPublicKey!)
        
        Button {
            if isFollowing {
                CurrentUser.unfollow(key: author.hexadecimalPublicKey!, context: viewContext)
            } else {
                CurrentUser.follow(key: author.hexadecimalPublicKey!, context: viewContext)
            }
        } label: {
            Text(isFollowing ? "Unfollow" : "Follow")
        }
    }
}
