//
//  FollowButton.swift
//  Nos
//
//  Created by Christopher Jorgensen on 2/24/23.
//

import SwiftUI
import Dependencies
import CoreData

struct FollowButton: View {
    @ObservedObject var currentUserAuthor: Author
    @ObservedObject var author: Author
    @Environment(\.managedObjectContext) private var viewContext
    @Dependency(\.analytics) private var analytics
    
    var body: some View {
        ActionButton(title: CurrentUser.isFollowing(author: author) ? .unfollow : .follow) {
            if CurrentUser.isFollowing(author: author) {
                CurrentUser.unfollow(author: author, context: viewContext)
                analytics.unfollowed(author)
            } else {
                CurrentUser.follow(author: author, context: viewContext)
                analytics.followed(author)
            }
        }
    }
}

struct FollowButton_Previews: PreviewProvider {
    
    static var persistenceController = PersistenceController.preview
    
    static var previewContext = {
        let context = persistenceController.viewContext
        return context
    }()
    
    static var user: Author {
        let author = Author(context: previewContext)
        author.hexadecimalPublicKey = KeyFixture.pubKeyHex
        return author
    }
    
    static var alice: Author = {
        let author = Author(context: previewContext)
        author.hexadecimalPublicKey = KeyFixture.alice.publicKeyHex
        author.name = "Alice"
        return author
    }()
    
    static var bob: Author = {
        let author = Author(context: previewContext)
        author.hexadecimalPublicKey = KeyFixture.bob.publicKeyHex
        author.name = "Bob"
        
        return author
    }()
    
    static func createTestData(in context: NSManagedObjectContext) {
        let follow = Follow(context: previewContext)
        follow.source = user
        follow.destination = alice
        // swiftlint:disable legacy_objc_type
        user.follows = NSSet(array: [follow])
        try! previewContext.save()
        CurrentUser.context = previewContext
        KeyChain.save(key: KeyChain.keychainPrivateKey, data: Data(KeyFixture.privateKeyHex.utf8))
    }
    
    static var previews: some View {
        VStack(spacing: 10) {
            FollowButton(currentUserAuthor: user, author: alice)
            // FollowButton(currentUserAuthor: user, author: bob)
        }
        .onAppear {
            // I can't get this to work, CurrentUser.context is always nil
            createTestData(in: previewContext)
        }
    }
}
