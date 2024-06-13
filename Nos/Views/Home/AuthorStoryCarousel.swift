import SwiftUI
import Dependencies

/// Shows a scrollable horizontal feed of authors who have unread stories.
struct AuthorStoryCarousel: View {
    
    @Binding var authors: [Author]
    @Binding var selectedStoryAuthor: Author?
    
    @EnvironmentObject private var router: Router
    @Dependency(\.relayService) private var relayService
    
    @State private var subscriptions = [ObjectIdentifier: SubscriptionCancellable]()
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 15) {
                ForEach(authors) { author in
                    Button {
                        withAnimation {
                            selectedStoryAuthor = author
                        }
                    } label: {
                        AuthorObservationView(authorID: author.hexadecimalPublicKey) { author in
                            StoryAvatarView(author: author)
                                .contextMenu {
                                    Button {
                                        router.push(author)
                                    } label: {
                                        Text(.localizable.seeProfile)
                                    }
                                }
                        }
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
            .padding(.horizontal, 15)
            .padding(.top, 15)
            .padding(.bottom, 0)
        }
        .readabilityPadding()
    }
}
