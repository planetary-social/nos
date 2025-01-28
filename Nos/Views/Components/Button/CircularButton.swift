import CoreData
import Dependencies
import Logger
import SwiftUI

/// A small, circular follow button that appears in the lower right corner of a user's avatar.
/// Allows the current user to follow or unfollow the author,
/// and updates its own appearance based on follow state.
struct CircularFollowButton: View {
    @ObservedObject var author: Author
    @Environment(CurrentUser.self) private var currentUser
    @Dependency(\.analytics) private var analytics
    @Dependency(\.crashReporting) private var crashReporting

    private let diameter: CGFloat = 30

    @State var disabled = false

    var body: some View {
        let following = currentUser.isFollowing(author: author)

        Button {
            disabled = true

            Task {
                defer { disabled = false }

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
        } label: {
            UserSelectionCircle(
                diameter: diameter,
                selected: following
            )
        }
        .disabled(disabled)
    }
}
