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
            VStack(spacing: 12) {
                HStack(alignment: .top) {
                    ZStack(alignment: .bottomTrailing) {
                        AvatarView(imageUrl: author.profilePhotoURL, size: 80)
                            .padding(.trailing, 12)
                        if showsFollowButton {
                            CircularFollowButton(author: author)
                        }
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(author.safeName)
                                    .lineLimit(1)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.primaryTxt)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                if author.hasNIP05 {
                                    NIP05View(author: author)
                                        .font(.clarity(.regular))
                                        .lineLimit(1)
                                } 
                            }

                            Spacer()

                            if author.muted {
                                Text("muted")
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

                KnownFollowersView(source: currentUser.author, destination: author)
            }
            .padding(.top, 20)
            .padding(.bottom, 12)
            .padding(.horizontal, 15)
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
    @Previewable @State var previewData = PreviewData()
    
    return VStack {
        AuthorCard(author: previewData.alice)
        AuthorCard(author: previewData.bob)
    }
    .padding()
    .inject(previewData: previewData)
}
