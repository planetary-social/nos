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
            if let expirationTime = note.expirationDate?.distanceFromNowString() {
                Image.disappearingMessages
                    .resizable()
                    .foregroundColor(.secondaryTxt)
                    .frame(width: 25, height: 25)
                Text(expirationTime)
                    .lineLimit(1)
                    .font(.body)
                    .foregroundColor(.secondaryTxt)
            } else if let elapsedTime = note.createdAt?.distanceFromNowString() {
                Text(elapsedTime)
                    .lineLimit(1)
                    .font(.body)
                    .foregroundColor(.secondaryTxt)
            }
        }
        .padding(.leading, 10)
    }
}

struct NoteCardHeader_Previews: PreviewProvider {
    static var previewData = PreviewData()
    static var previews: some View {
        NoteCardHeader(note: previewData.imageNote, author: previewData.previewAuthor)
            .inject(previewData: previewData)
        NoteCardHeader(note: previewData.expiringNote, author: previewData.previewAuthor)
            .inject(previewData: previewData)
    }
}
