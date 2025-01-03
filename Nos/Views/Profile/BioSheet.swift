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
        let bio = noteParser.parse(
            content: about,
            tags: [[]],
            context: viewContext
        )
        return bio
    }
    
    private var pronouns: String? {
        guard let pronouns = author.pronouns, !pronouns.isEmpty else {
            return nil
        }
        return pronouns
    }
    
    private var website: String? {
        guard let website = author.website, !website.isEmpty else {
            return nil
        }
        return website
    }

    private var websiteURL: URL? {
        guard let website = author.website, !website.isEmpty, let url = URL(string: website) else {
            return nil
        }

        guard let scheme = url.scheme, !scheme.isEmpty else {
            return URL(string: "https://\(website)")
        }

        return url
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
                } else if let npub = author.npubString {
                    Text("@\(npub)")
                        .foregroundStyle(Color.secondaryTxt)
                        .font(.footnote)
                        .textSelection(.enabled)
                }

                if author.hasMostrNIP05 {
                    ActivityPubBadgeView(author: author)
                }
                
                if let website {
                    Text("website")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.secondaryTxt)
                        .lineSpacing(10)
                        .shadow(
                            color: Color.bioSheetShadow,
                            radius: 4,
                            x: 0,
                            y: 4
                        )
                        .padding(.top, 34)

                    if let websiteURL {
                        Link(destination: websiteURL) {
                            Text(website)
                                .textSelection(.enabled)
                                .font(.body)
                                .foregroundStyle(Color.primaryTxt)
                                .tint(.accent)
                        }
                        .underline()
                    } else {
                        Text(website)
                            .textSelection(.enabled)
                            .font(.body)
                            .foregroundStyle(Color.primaryTxt)
                            .tint(.accent)
                    }
                }
                
                if let pronouns {
                    Text("pronouns")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.secondaryTxt)
                        .lineSpacing(10)
                        .shadow(
                            color: Color.bioSheetShadow,
                            radius: 4,
                            x: 0,
                            y: 4
                        )
                        .padding(.top, 34)
                    Text(pronouns)
                        .textSelection(.enabled)
                        .font(.body)
                        .foregroundStyle(Color.primaryTxt)
                        .tint(.accent)
                }
                
                if let bio {
                    Text("bio")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.secondaryTxt)
                        .lineSpacing(10)
                        .shadow(
                            color: Color.bioSheetShadow,
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
                    Text("bioMissing")
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
        BioSheet(author: previewData.eve)
            .inject(previewData: previewData)
            .padding()
            .background(Color.previewBg)
    }
}
