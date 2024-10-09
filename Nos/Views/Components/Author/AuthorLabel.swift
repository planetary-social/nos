import SwiftUI

struct AuthorLabel: View {
    
    final class Cache: ObservableObject {
        let attributedAuthor: AttributedString
        
        init(safeName: String, isReply: Bool?) {
            var authorName = AttributedString(safeName)
            authorName.foregroundColor = .primaryTxt
            authorName.font = .clarity(.semibold)
            if let isReply {
                let postedOrRepliedString = String(localized: isReply ? "replied" : "posted")
                var postedOrReplied = AttributedString(" " + postedOrRepliedString)
                postedOrReplied.foregroundColor = .secondaryTxt
                
                authorName.append(postedOrReplied)
            }
            attributedAuthor = authorName
        }
    }
    
    let profilePhotoURL: URL?
    
    @StateObject var cache: Cache
    
    init(safeName: String, profilePhotoURL: URL?, isReply: Bool? = nil) {
        self.profilePhotoURL = profilePhotoURL
        
        _cache = StateObject(wrappedValue: Cache(safeName: safeName, isReply: isReply))
    }

    var body: some View {
        HStack {
            AvatarView(imageUrl: profilePhotoURL, size: 24)
            Text(cache.attributedAuthor)
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
        let author = previewData.previewAuthor
        return AuthorLabel(
            safeName: author.safeName,
            profilePhotoURL: author.profilePhotoURL
        )
    }
}
