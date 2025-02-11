import SwiftUI

/// This view displays the information we have for an author suitable for being used in a list.
struct FollowsNotificationCard: View {
    @EnvironmentObject private var router: Router
    @Environment(\.managedObjectContext) private var viewContext
    let author: Author

    let viewModel: NotificationViewModel

    /// Whether the follow button should be displayed or not.
    private let showsFollowButton = true

    private func showFollowProfile() {
        guard let follower = try? Author.find(by: viewModel.authorID ?? "", context: viewContext) else {
            return
        }
        router.push(follower)
    }

    var body: some View {
        Button {
            showFollowProfile()
        } label: {
            VStack(spacing: 12) {
                HStack {
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
                                    .lineLimit(2)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.primaryTxt)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }

                        Text(String(localized: "startedFollowingYou"))
                            .lineLimit(2)
                            .font(.callout)
                    }

                    if let date = viewModel.date {
                        Text(date.distanceString())
                            .lineLimit(1)
                            .font(.callout)
                            .foregroundColor(.secondaryTxt)
                    }
                }
            }
            .padding(.top, 13)
            .padding(.bottom, 12)
            .padding(.leading, 12)
            .padding(.trailing, 12)
            .background(LinearGradient.cardBackground)
            .cornerRadius(cornerRadius)
        }
        .buttonStyle(CardButtonStyle(style: .compact))
    }

    var cornerRadius: CGFloat { 15 }
}

#Preview {
    var previewData = PreviewData()

    var alice: Author {
        previewData.alice
    }

    return VStack {
        Spacer()
        FollowsNotificationCard(
            author: alice,
            viewModel: NotificationViewModel(follower: alice, date: Date())
        )
        Spacer()
    }
    .inject(previewData: previewData)
}
