import SwiftUI

/// A view that displays one or more lines of read-only text presented as a badge.
///
///
/// This Text was implemented to be re-used in the wizards that set-up and delete usernames in EditProfile screen.
struct MastodonBadgeView: View {

    var body: some View {
        Label(LocalizedStringKey(stringLiteral: "mostr.pub"), image: "mastodon")
            .padding(.horizontal, 6)
            .padding(.vertical, 5)
            .font(.clarity(.bold, textStyle: .footnote))
            .foregroundStyle(Color.secondaryTxt)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(lineWidth: 1)
                    .foregroundColor(.secondaryTxt)
            )
    }
}

#Preview {
    MastodonBadgeView()
}

