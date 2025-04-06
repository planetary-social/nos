//
//  PictureNoteCard.swift
//  Nos
//
//  Created by Rabble on 03/02/2025.
//


import SwiftUI
struct PictureNoteCard: View {
    let note: Event
    let showsActions: Bool
    let showsLikeCount: Bool
    let showsRepostCount: Bool
    let cornerRadius: CGFloat
    let replyAction: ((Event) -> Void)?

    // Provide default values here so they're optional parameters when creating a PictureNoteCard.
    init(note: Event,
        showsActions: Bool = false,
        showsLikeCount: Bool = false,
        showsRepostCount: Bool = false,
        cornerRadius: CGFloat,
        replyAction: ((Event) -> Void)? = nil) {
        
        // Assign all properties at once using a tuple for better readability
        (self.note, self.showsActions, self.showsLikeCount, 
         self.showsRepostCount, self.cornerRadius, self.replyAction) = 
        (note, showsActions, showsLikeCount, 
         showsRepostCount, cornerRadius, replyAction)
    }

    var body: some View {
        VStack(spacing: 0) {
            if let title = note.getTagValue(key: "title") {
                Text(title)
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top, 8)
            }
            let imageMetaTags = note.getMediaMetaTags()
            if !imageMetaTags.isEmpty {
                TabView {
                    ForEach(imageMetaTags, id: \.self) { tag in
                        if let imageURL = note.getURLFromTag(tag) {
                            AsyncImage(url: imageURL) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            } placeholder: {
                                ProgressView()
                            }
                            .padding(.vertical)
                        }
                    }
                }
                .tabViewStyle(.page)
                .frame(height: 300)
            }
            if let content = note.content, !content.isEmpty {
                Text(content)
                    .padding()
            }
            if showsActions {
                BeveledSeparator()
                HStack(spacing: 0) {
                    Spacer()
                    RepostButton(note: note, showsCount: showsRepostCount)
                    LikeButton(note: note, showsCount: showsLikeCount)
                    ReplyButton(note: note, replyAction: replyAction)
                }
                .padding(.horizontal, 5)
                .padding(.vertical, 5)
            }
        }
        .background(
            LinearGradient.cardBackground
                .cornerRadius(cornerRadius)
        )
    }
}
