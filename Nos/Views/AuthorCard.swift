import SwiftUI

/// This view displays the information we have for an author suitable for being used in a list.
struct AuthorCard: View {
    @ObservedObject var author: Author
    @Environment(CurrentUser.self) var currentUser

    /// Whether the follow button should be displayed or not.
    let showsFollowButton: Bool

    var tapAction: (() -> Void)?
    
    /// Initializes an `AuthorCard` with the given parameters.
    /// - Parameters:
    ///   - author: The author to show in the card.
    ///   - showsFollowButton: Whether the follow button should be displayed or not. Defaults to `true`.
    ///   - onTap: The action to take when this card is tapped, if any. Defaults to `nil`.
    init(author: Author, showsFollowButton: Bool = true, onTap: (() -> Void)? = nil) {
        self.author = author
        self.showsFollowButton = showsFollowButton
        self.tapAction = onTap
    }

    var body: some View {
        Button {
            tapAction?()
        } label: {
            VStack(spacing: 13) {
                HStack(alignment: .top) {
                    ZStack(alignment: .bottomTrailing) {
                        AvatarView(imageUrl: author.profilePhotoURL, size: 80)
                            .padding(.trailing, 12)
                        if showsFollowButton {
                            CircularFollowButton(author: author)
                        }
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(author.safeName)
                                    .lineLimit(1)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.primaryTxt)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                if author.hasNIP05 {
                                    NIP05View(author: author)
                                        .font(.clarity(.semibold, textStyle: .title3))
                                        .lineLimit(1)
                                } else if author.hasUNS {
                                    UNSNameView(author: author)
                                        .font(.clarity(.semibold, textStyle: .title3))
                                }
                            }

                            Spacer()

                            if author.muted {
                                Text(.localizable.muted)
                                    .font(.subheadline)
                                    .foregroundColor(Color.secondaryTxt)
                            }
                        }

                        if let bio = author.about {
                            Text(bio)
                                .foregroundColor(.primaryTxt)
                                .multilineTextAlignment(.leading)
                                .lineSpacing(5)
                                .lineLimit(3)
                        }
                    }
                }
                KnownFollowersView(author: author)
            }
            .padding(15)
            .background(
                LinearGradient(
                    colors: [Color.cardBgTop, Color.cardBgBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(cornerRadius)
        }
        .buttonStyle(CardButtonStyle(style: .compact))
        .listRowInsets(EdgeInsets())
    }

    var cornerRadius: CGFloat { 15 }
}

#Preview {
    var previewData = PreviewData()
    
    return VStack {
        AuthorCard(author: previewData.alice)
        AuthorCard(author: previewData.unsAuthor, showsFollowButton: false)
        AuthorCard(author: previewData.bob)
    }
    .padding()
    .inject(previewData: previewData)
}
