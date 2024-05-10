import SwiftUI

/// A view that displays a badge with a mastodon icon.
///
///
/// This Text was implemented to be re-used in the Profile screen.
struct MastodonBadgeView: View {

    @ObservedObject var author: Author

    var fediverseServer: String {
        let regex = /[0-9A-Za-z._-]+_at_(?<fediverse>[0-9A-Za-z._-]+)@mostr\.pub/
        guard let match = author.nip05?.firstMatch(of: regex) else {
            return "mostr.pub"
        }
        let string = match.output.fediverse
        return String(string)
    }

    var body: some View {
        Label(LocalizedStringKey(stringLiteral: fediverseServer), image: "mastodon")
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
    var previewData = PreviewData()

    return VStack {
        MastodonBadgeView(author: previewData.alice)
    }
}
