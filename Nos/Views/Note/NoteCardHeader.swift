import SwiftUI

struct NoteCardHeader: View {
    
    let authorSafeName: String
    let authorProfilePhotoURL: URL?
    let noteExpirationDate: Date?
    let noteCreatedDate: Date?
    
    @State private var expirationDateDistanceString: String?
    @State private var createdDateDistanceString: String?
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            AuthorLabel(safeName: authorSafeName, profilePhotoURL: authorProfilePhotoURL)
            if let expirationDateDistanceString {
                Image.disappearingMessages
                    .resizable()
                    .foregroundColor(.secondaryTxt)
                    .frame(width: 25, height: 25)
                Text(expirationDateDistanceString)
                    .lineLimit(1)
                    .font(.clarity(.medium))
                    .foregroundColor(.secondaryTxt)
            } else if let createdDateDistanceString {
                Text(createdDateDistanceString)
                    .lineLimit(1)
                    .font(.clarity(.medium))
                    .foregroundColor(.secondaryTxt)
            }

            Spacer()
        }
        .padding(.leading, 10)
        .onAppear {
            expirationDateDistanceString = noteExpirationDate?.distanceString()
            createdDateDistanceString = noteCreatedDate?.distanceString()
        }
    }
}

struct NoteCardHeader_Previews: PreviewProvider {
    static var previewData = PreviewData()
    
    static var previews: some View {
        NoteCardHeader(
            authorSafeName: previewData.previewAuthor.safeName,
            authorProfilePhotoURL: previewData.previewAuthor.profilePhotoURL,
            noteExpirationDate: previewData.imageNote.expirationDate,
            noteCreatedDate: previewData.imageNote.createdAt
        )
        .inject(previewData: previewData)
        
        NoteCardHeader(
            authorSafeName: previewData.previewAuthor.safeName,
            authorProfilePhotoURL: previewData.previewAuthor.profilePhotoURL,
            noteExpirationDate: previewData.expiringNote.expirationDate,
            noteCreatedDate: previewData.expiringNote.createdAt
        )
        .inject(previewData: previewData)
    }
}
