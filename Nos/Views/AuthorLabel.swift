//
//  AuthorLabel.swift
//  Nos
//
//  Created by Matthew Lorentz on 6/15/23.
//

import SwiftUI

struct AuthorLabel: View {
    
    @ObservedObject var author: Author
    var note: Event?
    
    private var attributedAuthor: AttributedString {
        var authorName = AttributedString(author.safeName)
        authorName.foregroundColor = .primaryTxt
        authorName.font = Font.clarityBold
        if let note {
            let postedOrRepliedString = note.isReply ? Localized.Reply.replied.string : Localized.Reply.posted.string
            var postedOrReplied = AttributedString(" " + postedOrRepliedString)
            postedOrReplied.foregroundColor = .secondaryText
            
            authorName.append(postedOrReplied)
        }
        return authorName
    }

    var body: some View {
        HStack {
            AvatarView(imageUrl: author.profilePhotoURL, size: 24)
            Text(attributedAuthor)
                .lineLimit(1)
                .font(.brand)
                .multilineTextAlignment(.leading)
                .frame(alignment: .leading)
        }
    }
}

struct AuthorLabel_Previews: PreviewProvider {
    static var previews: some View {
        AuthorLabel(author: PreviewData.previewAuthor)
    }
}
