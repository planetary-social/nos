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
        VStack {
            HStack(alignment: .center) {
                AuthorLabel(author: author, note: note)
                    .padding(.trailing, 10)
                Spacer()
                let currentTime = Date()
                let oneHourAgo = Calendar.current.date(byAdding: .minute, value: -1, to: currentTime)
                // viewedAt >= oneHourAgo! ||
                if note.viewedAt == nil { //maybe it auto assigns a value?
                    NewPostFlagView()
                } else
                {
                  Text("SHIT")
                }
                if let elapsedTime = note.createdAt?.elapsedTimeFromNowString() {
                    Text(elapsedTime)
                        .lineLimit(1)
                        .font(.body)
                        .foregroundColor(.secondaryText)
                }
            }
            .padding(.leading, 10)
            
            // Check if note.viewedAt is set and older than 10 minutes ago

        }
    }
}

struct AuthorHeader_Previews: PreviewProvider {
    static var previewData = PreviewData()
    static var previews: some View {
        NoteCardHeader(note: previewData.imageNote, author: previewData.previewAuthor)
    }
}
