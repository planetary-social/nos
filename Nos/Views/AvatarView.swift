//
//  AvatarView.swift
//  Nos
//
//  Created by Shane Bielefeld on 2/17/23.
//

import SwiftUI
import SDWebImageSwiftUI

struct AvatarView: View {
    
    var imageUrl: URL?
    var size: CGFloat
    
    var body: some View {
        WebImage(url: imageUrl)
            .resizable()
            .placeholder { 
                Image.emptyAvatar
                    .resizable()
                    .renderingMode(.original)
            }
            .indicator(.activity)
            .aspectRatio(contentMode: .fill)
            .frame(width: size, height: size)
            .clipShape(Circle())
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
