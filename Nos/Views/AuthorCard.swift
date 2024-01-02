//
//  AuthorCard.swift
//  Nos
//
//  Created by Matthew Lorentz on 6/5/23.
//

import SwiftUI

/// This view displays the information we have for an author suitable for being used in a list.
struct AuthorCard: View {

    @ObservedObject var author: Author

    @Environment(\.managedObjectContext) private var viewContext

    var tapAction: (() -> Void)?
 
    init(author: Author, onTap: (() -> Void)? = nil) {
        self.author = author
        self.tapAction = onTap
    }

    var body: some View {
        Button {
            tapAction?()
        } label: {
            VStack(spacing: 13) {
                HStack {
                    AvatarView(imageUrl: author.profilePhotoURL, size: 80)
                        .padding(.trailing, 12)
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            PlainText(author.safeName)
                                .lineLimit(1)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(Color.primaryTxt)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            if author.muted {
                                Text(.localizable.muted)
                                    .font(.subheadline)
                                    .foregroundColor(Color.secondaryTxt)
                            }
                        }
                        
                        if !(author.uns ?? "").isEmpty {
                            UNSNameView(author: author)
                        } else {
                            NIP05View(author: author)
                        }
                        
                        if let bio = author.about {
                            PlainText(bio)
                                .foregroundColor(.secondaryTxt)
                                .font(.claritySubheadline)
                                .multilineTextAlignment(.leading)
                                .lineSpacing(5)
                                .lineLimit(2)
                        }
                    }
                }
                KnownFollowersView(author: author)
            }
            .padding(15)
            .background(
                LinearGradient(
                    colors: [Color.cardBgTop, Color.cardBgBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(cornerRadius)
        }
        .buttonStyle(CardButtonStyle(style: .compact))
        .listRowInsets(EdgeInsets())
    }

    var cornerRadius: CGFloat { 15 }
}

#Preview {
    var previewData = PreviewData()
    
    return VStack {
        AuthorCard(author: previewData.alice) 
        AuthorCard(author: previewData.unsAuthor) 
        AuthorCard(author: previewData.bob) 
    }
    .padding()
    .inject(previewData: previewData)
}
