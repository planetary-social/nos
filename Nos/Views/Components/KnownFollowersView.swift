import Foundation
import SwiftUI

/// Shows a list of followers of the given author that the logged in user might know. This helps the user avoid
/// impersonation attacks by making sure they choose the right person to follow, mention, message, etc. 
struct KnownFollowersView: View {
    
    @ObservedObject var author: Author
    
    /// The authors that the `source` author follows who also follow the `author`
    @FetchRequest private var knownFollowers: FetchedResults<Author>
    
    /// The authors that will be featured with profile pictures and names
    var displayedAuthors: ArraySlice<Author> {
        knownFollowers
            .filter { $0.hasHumanFriendlyName }
            .filter { $0.profilePhotoURL != nil }
            .prefix(3)
    }
    
    /// The avatars of the authors that will be featured with profile pictures and names
    var avatarURLs: [URL?] {
        displayedAuthors.compactMap { $0.profilePhotoURL }
    }
    
    /// The text that will be displayed alongside the avatars listing some of the displayedAuthor's names
    var followText: Text {
        let followString: String
        let authors = self.displayedAuthors
        switch authors.count {
        case 0: 
            return Text("")
        case 1:
            guard let name = authors[safe: 0]?.safeName else {
                return Text("")
            }
            followString = String.localizedStringWithFormat(String(localized: "followedByOne"), name)
        case 2:
            guard let firstName = authors[safe: 0]?.safeName,
                let secondName = authors[safe: 1]?.safeName else {
                return Text("")
            }
            followString = String.localizedStringWithFormat(String(localized: "followedByTwo"), firstName, secondName)
        default:
            guard let firstName = authors[safe: 0]?.safeName,
                let secondName = authors[safe: 1]?.safeName else {
                return Text("")
            }
            followString = String.localizedStringWithFormat(
                String(localized: "followedByTwoAndMore"), firstName, secondName, knownFollowers.count - 2
            )
        }

        let attributedString = (try? AttributedString(markdown: followString)) ?? AttributedString(followString)
            .replacingAttributes(
                AttributeContainer(
                    [.inlinePresentationIntent: InlinePresentationIntent.stronglyEmphasized.rawValue]
                ),
                with: AttributeContainer(
                    [.foregroundColor: UIColor(.primaryTxt)]
                )
            )
        return Text(attributedString)
    }
    
    init(source: Author?, destination: Author) {
        self.author = destination
        if let source {
            self._knownFollowers = FetchRequest(fetchRequest: source.knownFollowers(of: destination))
        } else {
            self._knownFollowers = FetchRequest(fetchRequest: Author.emptyRequest())
        } 
    }
    
    var body: some View {
        if knownFollowers.isEmpty == false {
            HStack {
                HStack {
                    Spacer()
                    StackedAvatarsView(avatarUrls: avatarURLs, border: 4)
                }
                .frame(width: 92)

                followText
                    .font(.footnote)

                Spacer()
            }
            .foregroundColor(.secondaryTxt)
        } else {
            EmptyView()
        }
    }
}

#Preview {
    var previewData = PreviewData()
    
    return VStack {
        KnownFollowersView(source: previewData.currentUser.author, destination: previewData.alice)
        // should display nothing
        KnownFollowersView(source: previewData.currentUser.author, destination: previewData.bob)
    }
    .background(Color.appBg)
    .padding()
    .inject(previewData: previewData)
}
