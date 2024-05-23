import SwiftUI

struct ProfileKnownFollowersView: View {
    var first: Author
    var knownFollowers: [Follow]
    var followers: [Follow]

    private func attributedText(from stringResource: LocalizedStringResource) -> AttributedString {
        let attributedString = AttributedString(localized: stringResource)
        let bold = InlinePresentationIntent.stronglyEmphasized.rawValue
        return attributedString.replacingAttributes(
            AttributeContainer(
                [.inlinePresentationIntent: bold]
            ),
            with: AttributeContainer(
                [.foregroundColor: UIColor(Color.primaryTxt)]
            )
        )
    }

    var body: some View {
        HStack {
            if let second = knownFollowers[safe: 1]?.source {
                StackedAvatarsView(
                    avatarUrls: [first.profilePhotoURL, second.profilePhotoURL]
                )
                if followers.count > 2 {
                    Text(
                        attributedText(
                            from: .localizable.followedByTwoAndMore(
                                first.safeName,
                                second.safeName,
                                followers.count - 2
                            )
                        )
                    )
                } else {
                    Text(
                        attributedText(
                            from: .localizable.followedByTwo(
                                first.safeName,
                                second.safeName
                            )
                        )
                    )
                }
            } else {
                StackedAvatarsView(avatarUrls: [first.profilePhotoURL])
                if followers.count > 1 {
                    Text(
                        attributedText(
                            from: .localizable.followedByOneAndMore(
                                first.safeName,
                                followers.count - 1
                            )
                        )
                    )
                } else {
                    Text(
                        attributedText(
                            from: .localizable.followedByOne(
                                first.safeName
                            )
                        )
                    )
                }
            }
        }
        .font(.footnote)
        .foregroundColor(Color.secondaryTxt)
        .padding(EdgeInsets(top: 0, leading: 18, bottom: 0, trailing: 18))
        .multilineTextAlignment(.leading)
    }
}
