import SwiftUI

/// This view displays the information we have for an author suitable for being used in a list.
struct FollowsNotificationCard: View {
    @EnvironmentObject private var router: Router
    @Environment(\.managedObjectContext) private var viewContext
    var author: Author

    let viewModel: NotificationViewModel

    /// Whether the follow button should be displayed or not.
    let showsFollowButton: Bool

    init(author: Author, viewModel: NotificationViewModel, showsFollowButton: Bool = true) {
        self.author = author
        self.viewModel = viewModel
        self.showsFollowButton = showsFollowButton
    }

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
                                    .lineLimit(1)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.primaryTxt)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }

                        Text("started following you")
                            .lineLimit(2)
                    }

                    if let date = viewModel.date {
                        Text(date.distanceString())
                            .lineLimit(1)
                            .font(.clarity(.regular))
                            .foregroundColor(.secondaryTxt)
                    }
                }
            }
            .padding(.top, 20)
            .padding(.bottom, 12)
            .padding(.horizontal, 15)
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
