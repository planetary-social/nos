import SwiftUI

struct AuthorLabel: View {
    
    @ObservedObject var author: Author
    var note: Event?
    
    private var attributedAuthor: AttributedString {
        var authorName = AttributedString(author.safeName)
        authorName.foregroundColor = .primaryTxt
        authorName.font = .clarity(.semibold)
        if let note {
            let postedOrRepliedString = String(localized: note.isReply ? .reply.replied : .reply.posted)
            var postedOrReplied = AttributedString(" " + postedOrRepliedString)
            postedOrReplied.foregroundColor = .secondaryTxt
            
            authorName.append(postedOrReplied)
        }
        return authorName
    }

    var body: some View {
        HStack {
            AvatarView(imageUrl: author.profilePhotoURL, size: 24)
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
        AuthorLabel(author: previewData.previewAuthor)
    }
}
