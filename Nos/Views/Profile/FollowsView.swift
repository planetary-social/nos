import Dependencies
import Foundation
import SwiftUI

struct FollowsDestination: Hashable {
    var author: Author
    var follows: [Author]
}

struct FollowersDestination: Hashable {
    var author: Author
    var followers: [Author]
}

/// Displays a list of people someone is following.
struct FollowsView: View {
    /// Screen title
    var title: LocalizedStringKey

    /// Sorted list of authors to display in the list
    var authors: [Author]

    /// Subscriptions for metadata requests from the relay service, keyed by author ID.
    @State private var subscriptions = [ObjectIdentifier: SubscriptionCancellable]()

    @Dependency(\.relayService) private var relayService
    @EnvironmentObject private var router: Router

    init(
        _ title: LocalizedStringKey,
        authors: [Author],
        subscriptions: [ObjectIdentifier: SubscriptionCancellable] = [ObjectIdentifier: SubscriptionCancellable]()
    ) {
        self.title = title
        self.authors = authors
        self.subscriptions = subscriptions
    }
    
    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(authors) { author in
                    AuthorObservationView(authorID: author.hexadecimalPublicKey) { author in
                        AuthorCard(author: author) {
                            router.push(author)
                        }
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
        .nosNavigationBar(title)
    }
}
