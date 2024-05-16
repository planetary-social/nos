import SwiftUI
import Dependencies
import CoreData

struct FollowButton: View {
    @ObservedObject var currentUserAuthor: Author
    @ObservedObject var author: Author
    @Environment(CurrentUser.self) var currentUser
    @Dependency(\.analytics) private var analytics
    @Dependency(\.crashReporting) private var crashReporting
    
    var body: some View {
        let following = currentUser.isFollowing(author: author)
        ActionButton(title: following ? .localizable.unfollow : .localizable.follow) {
            do {
                if following {
                    try await currentUser.unfollow(author: author)
                    analytics.unfollowed(author)
                } else {
                    try await currentUser.follow(author: author)
                    analytics.followed(author)
                }
            } catch {
                crashReporting.report(error)
            }
        }
    }
}

#Preview {
    var persistenceController = PersistenceController.preview
    
    var previewContext = {
        let context = persistenceController.viewContext
        return context
    }()
    
    var user: Author {
        let author = Author(context: previewContext)
        author.hexadecimalPublicKey = KeyFixture.pubKeyHex
        return author
    }
    
    var alice: Author = {
        let author = Author(context: previewContext)
        author.hexadecimalPublicKey = KeyFixture.alice.publicKeyHex
        author.name = "Alice"
        return author
    }()
    
    var bob: Author = {
        let author = Author(context: previewContext)
        author.hexadecimalPublicKey = KeyFixture.bob.publicKeyHex
        author.name = "Bob"
        
        return author
    }()
    
    func createTestData(in context: NSManagedObjectContext) {
        let follow = Follow(context: previewContext)
        follow.source = user
        follow.destination = alice
        user.follows = Set([follow])
        try? previewContext.save()
        KeyChain.save(key: KeyChain.keychainPrivateKey, data: Data(KeyFixture.privateKeyHex.utf8))
    }

    return VStack(spacing: 10) {
        FollowButton(currentUserAuthor: user, author: alice)
        // FollowButton(currentUserAuthor: user, author: bob)
    }
    .onAppear {
        // I can't get this to work, currentUser.context is always nil
        createTestData(in: previewContext)
    }
}
