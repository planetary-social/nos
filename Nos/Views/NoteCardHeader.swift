//
//  NoteCardHeader.swift
//  Nos
//
//  Created by Matthew Lorentz on 6/15/23.
//

import SwiftUI

struct NoteCardHeader: View {
    
    @ObservedObject var note: Event
    @ObservedObject var author: Author
    
    var body: some View {
        HStack(alignment: .center) {
            AuthorLabel(author: author, note: note)
            Spacer()
            if let elapsedTime = note.createdAt?.elapsedTimeFromNowString() {
                Text(elapsedTime)
                    .lineLimit(1)
                    .font(.body)
                    .foregroundColor(.secondaryText)
            }
        }
        .padding(.leading, 10)
    }
}

struct AuthorHeader_Previews: PreviewProvider {
    static var previewData = PreviewData()
    static var previews: some View {
        NoteCardHeader(note: previewData.imageNote, author: previewData.previewAuthor)
    }
}
