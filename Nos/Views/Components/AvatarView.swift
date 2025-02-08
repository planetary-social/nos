import SwiftUI
import SDWebImageSwiftUI

struct AvatarView: View {
    
    var imageUrl: URL?
    let size: CGFloat
    
    var body: some View {
        WebImage(
            url: imageUrl,
            content: { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            },
            placeholder: {
                Image.emptyAvatar
                    .resizable()
                    .renderingMode(.original)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            }
        )
    }
}

struct AvatarView_Previews: PreviewProvider {
    
    static let avatarURL = URL(string: "https://tinyurl.com/47amhyzz") ?? URL.homeDirectory
    
    static var previews: some View {
        VStack {
            AvatarView(imageUrl: avatarURL, size: 24)
            AvatarView(imageUrl: avatarURL, size: 45)
            AvatarView(imageUrl: avatarURL, size: 87)
        }
        VStack {
            AvatarView(size: 24)
            AvatarView(size: 45)
            AvatarView(size: 87)
        }
    }
}
