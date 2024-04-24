import SwiftUI

/// Shows a scrollable horizontal feed of authors who have unread stories.
struct AuthorStoryCarousel: View {
    
    @Binding var authors: [Author]
    @Binding var selectedStoryAuthor: Author?
    
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var relayService: RelayService
    @State private var relaySubscriptions = [SubscriptionCancellable]()
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                ForEach(authors) { author in
                    Button {
                        withAnimation {
                            selectedStoryAuthor = author
                        }
                    } label: {
                        StoryAvatarView(author: author)
                            .contextMenu {
                                Button {
                                    router.push(author)
                                } label: {
                                    Text(.localizable.seeProfile)
                                }
                            }
                            .onAppear {
                                Task {
                                    await fetchMetadata(for: author)
                                }
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
    
    func fetchMetadata(for author: Author) async {
        let subscription = await relayService.requestMetadata(for: author.hexadecimalPublicKey, since: author.lastUpdatedMetadata)   
        relaySubscriptions.append(subscription)
        // todo: it seems like this is running correclty but author photos aren't updating right away
    }
}
