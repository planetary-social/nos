import SwiftUI

struct AuthorLabel: View {
    
    let name: String
    let profilePhotoURL: URL?

    var body: some View {
        HStack {
            AvatarView(imageUrl: profilePhotoURL, size: 24)
            Text(name)
                .lineLimit(1)
                .foregroundStyle(Color.primaryTxt)
                .font(.clarity(.semibold))
                .multilineTextAlignment(.leading)
                .frame(alignment: .leading)
        }
    }
}

struct AuthorLabel_Previews: PreviewProvider {
    static var previewData = PreviewData()
    static var previews: some View {
        AuthorLabel(
            name: previewData.previewAuthor.safeName,
            profilePhotoURL: previewData.previewAuthor.profilePhotoURL
        )
    }
}
