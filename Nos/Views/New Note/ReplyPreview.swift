import SwiftUI

/// This is a component of `NewNoteView` that displays a preview of the note being replied to. 
struct ReplyPreview: View {
    
    var note: Event
    @Environment(CurrentUser.self) var currentUser
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                AvatarView(imageUrl: note.author?.profilePhotoURL, size: 30)
                Text(note.author?.safeName ?? "")
                    .foregroundColor(.primaryTxt)
                    .bold()
                Text(note.createdAt?.distanceString() ?? "")
                    .foregroundColor(.secondaryTxt)
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            
            CompactNoteView(note: note, showLinkPreviews: false, truncationLineLimit: 5, allowUserInteraction: false)
                .padding(.horizontal, 9)
            
            HStack {
                AvatarView(imageUrl: currentUser.author?.profilePhotoURL, size: 30)
                Text(currentUser.author?.safeName ?? "")
                    .foregroundColor(.primaryTxt)
                    .bold()
                Text("now")
                    .foregroundColor(.secondaryTxt)
                Spacer()
            }
            .padding(.horizontal, 24)
        }
    }
}

#Preview {
    var previewData = PreviewData()
    
    return ReplyPreview(note: previewData.longNote)
        .background(Color.appBg)
        .inject(previewData: previewData)
}
