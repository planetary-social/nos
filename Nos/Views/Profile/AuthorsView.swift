import Dependencies
import Foundation
import SwiftUI

struct FollowsDestination: Hashable {
    let author: Author
    let follows: [Author]
}

struct FollowersDestination: Hashable {
    let author: Author
    let followers: [Author]
}

/// Displays a list of authors.
struct AuthorsView: View {
    /// Screen title
    let title: LocalizedStringKey?

    /// Sorted list of authors to display in the list
    let authors: [Author]
    
    let avatarOverlayMode: AvatarOverlayMode
    
    let onTapGesture: ((Author) -> Void)?

    /// Subscriptions for metadata requests from the relay service, keyed by author ID.
    @State private var subscriptions = [ObjectIdentifier: SubscriptionCancellable]()

    @Dependency(\.relayService) private var relayService
    @EnvironmentObject private var router: Router

    init(
        _ title: LocalizedStringKey? = nil,
        authors: [Author],
        avatarOverlayMode: AvatarOverlayMode = .follows,
        onTapGesture: ((Author) -> Void)? = nil
    ) {
        self.title = title
        self.authors = authors
        self.avatarOverlayMode = avatarOverlayMode
        self.onTapGesture = onTapGesture
    }
    
    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(authors) { author in
                    AuthorObservationView(authorID: author.hexadecimalPublicKey) { author in
                        AuthorCard(
                            author: author,
                            avatarOverlayView: {
                                switch avatarOverlayMode {
                                case .follows:
                                    AnyView(CircularFollowButton(author: author))
                                case .alwaysSelected:
                                    AnyView(UserSelectionCircle(diameter: 30, selected: true))
                                case .inSet(let authors):
                                    AnyView(UserSelectionCircle(diameter: 30, selected: authors.contains(author)))
                                }
                            },
                            onTap: {
                                if let onTapGesture {
                                    onTapGesture(author)
                                } else {
                                    router.push(author)
                                }
                            }
                        )
                        .padding(.horizontal, 13)
                        .padding(.top, 5)
                        .readabilityPadding()
                        .task {
                            subscriptions[author.id] =
                            await relayService.requestMetadata(
                                for: author.hexadecimalPublicKey,
                                since: author.lastUpdatedMetadata
                            )
                        }
                    }
                }
            }
            .padding(.vertical, 12)
        }
        .background(Color.appBg)
        .nosNavigationBar(title ?? "")
    }
}
