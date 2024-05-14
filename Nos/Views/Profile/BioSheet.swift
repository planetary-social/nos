import Dependencies
import SwiftUI

/// Shows the name, nip-05 and bio of a given user in a vertical stack.
struct BioSheet: View {
    @ObservedObject var author: Author

    @Environment(\.managedObjectContext) private var viewContext
    @Dependency(\.noteParser) private var noteParser

    private var bio: AttributedString? {
        guard let about = author.about, !about.isEmpty else {
            return nil
        }
        let (bio, _) = noteParser.parse(
            content: about,
            tags: [[]],
            context: viewContext
        )
        return bio
    }

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 13) {
                Spacer(minLength: 26)

                Text(author.safeName)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(Color.primaryTxt)
                    .textSelection(.enabled)

                if author.hasNIP05 {
                    NIP05View(author: author)
                        .font(.footnote)
                }

                if author.hasMostrNIP05 {
                    ActivityPubBadgeView(author: author)
                }

                if let bio {
                    Text(.localizable.bio)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.secondaryTxt)
                        .lineSpacing(10)
                        .shadow(
                            color: Color(white: 0, opacity: 0.25),
                            radius: 4,
                            x: 0,
                            y: 4
                        )
                        .padding(.top, 34)
                    Text(bio)
                        .textSelection(.enabled)
                        .font(.body)
                        .foregroundStyle(Color.primaryTxt)
                        .tint(.accent)
                } else {
                    Text(.localizable.bioMissing)
                        .font(.body)
                        .foregroundStyle(Color.secondaryTxt)
                        .padding(.top, 34)
                }
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background {
            LinearGradient.bio
        }
    }
}

#Preview("BioSheet") {
    var previewData = PreviewData()

    return Group {
        BioSheet(author: previewData.unsAuthor)
            .inject(previewData: previewData)
            .padding()
            .background(Color.previewBg)
    }
}
