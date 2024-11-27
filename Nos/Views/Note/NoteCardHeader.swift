import SwiftUI

struct NoteCardHeader: View {
    
    @ObservedObject var note: Event
    @ObservedObject var author: Author
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            AuthorLabel(author: author, note: note)
            if let expirationTime = note.expirationDate?.distanceString() {
                Image.disappearingMessages
                    .resizable()
                    .foregroundColor(.secondaryTxt)
                    .frame(width: 25, height: 25)
                Text(expirationTime)
                    .lineLimit(1)
                    .font(.clarity(.medium))
                    .foregroundColor(.secondaryTxt)
            } else if let elapsedTime = note.createdAt?.distanceString() {
                Text(elapsedTime)
                    .lineLimit(1)
                    .font(.clarity(.medium))
                    .foregroundColor(.secondaryTxt)
            }

            Spacer()
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
