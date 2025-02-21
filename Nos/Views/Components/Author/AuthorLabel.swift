import SwiftUI

struct AuthorLabel: View {
    
    let profilePhotoURL: URL?
    private let attributedAuthor: AttributedString
    
    init(safeName: String, profilePhotoURL: URL?) {
        self.profilePhotoURL = profilePhotoURL
        
        var authorName = AttributedString(safeName)
        authorName.foregroundColor = .primaryTxt
        authorName.font = .clarity(.semibold)
        attributedAuthor = authorName
    }

    var body: some View {
        HStack {
            AvatarView(imageUrl: profilePhotoURL, size: 24)
            Text(attributedAuthor)
                .lineLimit(1)
                .font(.clarity(.medium))
                .multilineTextAlignment(.leading)
                .frame(alignment: .leading)
        }
    }
}

struct AuthorLabel_Previews: PreviewProvider {
    static var previewData = PreviewData()
    static var previews: some View {
        AuthorLabel(
            safeName: previewData.previewAuthor.safeName,
            profilePhotoURL: previewData.previewAuthor.profilePhotoURL
        )
    }
}
