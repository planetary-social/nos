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
    var title: LocalizedStringResource

    /// Sorted list of authors to display in the list
    var authors: [Author]
    
    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 15) {
                ForEach(authors) { author in
                    FollowCard(author: author)
                        .padding(.horizontal)
                        .readabilityPadding()
                }
            }
            .padding(.top)
        }
        .background(Color.appBg)
        .nosNavigationBar(title: title)
    }
}
