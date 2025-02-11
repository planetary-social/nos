import SwiftUI

struct ProfileKnownFollowersView: View {
    let first: Author
    let knownFollowers: [Follow]
    let followers: [Follow]

    private func attributedText(from content: String) -> AttributedString {
        let attributedString = (try? AttributedString(markdown: content)) ?? AttributedString(content)
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
                            from: String.localizedStringWithFormat(
                                String(localized: "followedByTwoAndOthers"), first.safeName, second.safeName
                            )
                        )
                    )
                } else {
                    Text(
                        attributedText(
                            from: String.localizedStringWithFormat(
                                String(localized: "followedByTwo"), first.safeName, second.safeName
                            )
                        )
                    )
                }
            } else {
                StackedAvatarsView(avatarUrls: [first.profilePhotoURL])
                if followers.count > 1 {
                    Text(
                        attributedText(
                            from: String.localizedStringWithFormat(
                                String(localized: "followedByOneAndOthers"), first.safeName
                            )
                        )
                    )
                } else {
                    Text(
                        attributedText(
                            from: String.localizedStringWithFormat(
                                String(localized: "followedByOne"), first.safeName
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
