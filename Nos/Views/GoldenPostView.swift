//
//  GoldenPostView.swift
//  Planetary
//
//  Created by Martin Dutra on 29/12/22.
//  Copyright © 2022 Verse Communications Inc. All rights reserved.
//

import SwiftUI

struct GoldenPostView: View {

    var author: Author

    var note: Event {
        didSet {
            if let eventAuthor = note.author {
                self.author = eventAuthor
            }
        }
    }

    private let goldenRatio: CGFloat = 0.618
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @EnvironmentObject private var router: Router

    var text: some View {
        Text(note.attributedContent(with: viewContext) ?? "")
            .foregroundColor(.primaryTxt)
            .accentColor(.accent)
            .environment(\.openURL, OpenURLAction { url in
                router.open(url: url, with: viewContext)
                return .handled
            })
    }

    var footer: some View {
        HStack(alignment: .center) {
            Button {
                router.path.append(author)
            } label: {
                HStack(alignment: .center) {
                    AvatarView(imageUrl: author.profilePhotoURL, size: 20)
                    // if !post.isBlobOnly {
                    Text(author.safeName)
                        .lineLimit(1)
                        .font(.subheadline)
                        .foregroundColor(Color.secondaryTxt)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    // }
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(10)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // swiftlint:disable indentation_width
//            if post.isBlobOnly {
//                ZStack(alignment: .bottom) {
//                    BlobGalleryView(blobs: blobs, aspectRatio: goldenRatio)
//                        .allowsHitTesting(false)
//                    footer
//                }
//            } else {
//                if !blobs.isEmpty {
//                    BlobGalleryView(blobs: blobs)
//                        .allowsHitTesting(false)
//                        .frame(maxWidth: .infinity, alignment: .leading)
//                        .layoutPriority(1)
//                }

//                if post.isTextOnly {
                    text
                        .padding(EdgeInsets(top: 15, leading: 10, bottom: 15, trailing: 10))
//                } else {
//                    text
//                        .padding(EdgeInsets(top: 8, leading: 10, bottom: 0, trailing: 10))
//                }
//                Spacer(minLength: 0)
                footer
//            }
        }
        // swiftlint:enable indentation_width
        .frame(maxWidth: .infinity, alignment: .leading)
        .aspectRatio(goldenRatio, contentMode: ContentMode.fill)
    }
}

struct GoldenPostView_Previews: PreviewProvider {
    
    static var persistenceController = PersistenceController.preview
    static var previewContext = persistenceController.container.viewContext
    
    static var shortNote: Event {
        let note = Event(context: previewContext)
        note.content = "Hello, world!"
        return note
    }
    
    static var previewAuthor = Author(context: previewContext)
    
    static var longNote: Event {
        let note = Event(context: previewContext)
        note.content = .loremIpsum(5)
        let author = Author(context: previewContext)
        // TODO: derive from private key
        author.hexadecimalPublicKey = "32730e9dfcab797caf8380d096e548d9ef98f3af3000542f9271a91a9e3b0001"
        note.author = author
        note.author?.profilePhotoURL = URL(string: "https://avatars.githubusercontent.com/u/1165004?s=40&v=4")
        return note
    }
 
    static var previews: some View {
        Group {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible())], spacing: 10) {
                Group {
                    GoldenPostView(author: previewAuthor, note: shortNote)
                    GoldenPostView(author: previewAuthor, note: longNote)
                }
                .background(Color.cardBackground)
            }
            VStack {
                GoldenPostView(author: previewAuthor, note: shortNote)
                GoldenPostView(author: previewAuthor, note: longNote)
            }
            .preferredColorScheme(.dark)
        }
        .padding(10)
        .background(Color.appBg)
    }
}
