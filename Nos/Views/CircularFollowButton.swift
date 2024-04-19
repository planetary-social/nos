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

    var body: some View {
        let following = currentUser.isFollowing(author: author)

        Button {
            Task {
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
        } label: {
            ZStack {
                Circle()
                    .frame(width: diameter)
                    .foregroundStyle(
                        LinearGradient(
                            colors: following ?
                            [Color.actionSecondaryGradientTop, Color.actionSecondaryGradientBottom] :
                                [Color.actionPrimaryGradientTop, Color.actionPrimaryGradientBottom],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .background(
                        Circle()
                            .frame(width: diameter)
                            .offset(y: 1)
                            .foregroundStyle(
                                following ?
                                Color.actionSecondaryBackground :
                                Color.actionPrimaryBackground
                            )
                    )
                if following {
                    Image.followingIcon
                } else {
                    Image.followIcon
                }
            }
        }
    }
}
