import SwiftUI
import Dependencies
import CoreData

struct FollowButton: View {
    @ObservedObject var currentUserAuthor: Author
    @ObservedObject var author: Author
    /// A flag used to show a follow or unfollow icon in addition to Follow or
    /// Unfollow text.
    var shouldDisplayIcon = false
    /// A flag used to fill the available horizontal space (centering the
    /// contents) or to fit the horizontal space to the contents of the action
    /// button.
    var shouldFillHorizontalSpace = false
    @Environment(CurrentUser.self) private var currentUser
    @Dependency(\.analytics) private var analytics
    @Dependency(\.crashReporting) private var crashReporting
    
    /// Returns an icon associated to the follow or unfollow state.
    private func image(for following: Bool) -> Image? {
        guard shouldDisplayIcon else {
            return nil
        }
        return following ? Image.slimFollowingIcon : Image.slimFollowIcon
    }
    
    var body: some View {
        let following = currentUser.isFollowing(author: author)
        ActionButton(
            following ? "unfriend" : "friend",
            font: .clarity(.bold, textStyle: .subheadline),
            image: image(for: following),
            shouldFillHorizontalSpace: shouldFillHorizontalSpace
        ) {
            do {
                if following {
                    try await currentUser.unfollow(author: author)
                    analytics.unfollowed(author)
                } else {
                    try await currentUser.follow(author: author)
                    analytics.followed(author)
                    GoToFeedTip.followedAccount.sendDonation()
                }
            } catch {
                crashReporting.report(error)
            }
        }
    }
}

struct FollowButton_Previews: PreviewProvider {
    
    static var previewData = PreviewData()
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
    
    static func createTestData(in context: NSManagedObjectContext) {
        let follow = Follow(context: previewContext)
        follow.source = user
        follow.destination = alice
        user.follows = Set([follow])
        try? previewContext.save()
    }
    
    static var previews: some View {
        VStack(spacing: 10) {
            FollowButton(currentUserAuthor: user, author: alice)
            // FollowButton(currentUserAuthor: user, author: bob)
        }
        .onAppear {
            // I can't get this to work, currentUser.context is always nil
            createTestData(in: previewContext)
        }
        .environment(previewData.currentUser)
    }
}
