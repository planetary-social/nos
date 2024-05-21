import SwiftUI

/// Shows a scrollable horizontal feed of authors who have unread stories.
struct AuthorStoryCarousel: View {
    
    @Binding var authors: [Author]
    @Binding var selectedStoryAuthor: Author?
    
    @EnvironmentObject private var router: Router
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 15) {
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
