import SwiftUI

/// A view that displays a badge with an ActivityPub icon.
struct ActivityPubBadgeView: View {

    @ObservedObject var author: Author

    var fediverseServer: String {
        let regex = /[0-9A-Za-z._-]+@(?<fediverse>[0-9A-Za-z._-]+)\.mostr\.pub/
        guard let match = author.nip05?.firstMatch(of: regex) else {
            return "mostr.pub"
        }
        let string = match.output.fediverse
        return String(string)
    }

    var body: some View {
        Label(LocalizedStringKey(stringLiteral: fediverseServer), image: "ActivityPub")
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
        ActivityPubBadgeView(author: previewData.alice)
    }
}
