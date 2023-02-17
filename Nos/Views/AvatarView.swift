//
//  AvatarView.swift
//  Nos
//
//  Created by Shane Bielefeld on 2/17/23.
//

import SwiftUI

struct AvatarView: View {
    
    var imageUrl: URL?
    var size: CGFloat
    
    var body: some View {
        Group {
            if let imageUrl = imageUrl {
                AsyncImage(
                    url: imageUrl,
                    content: { image in
                        image.resizable()
                    }, placeholder: {
                        ProgressView()
                    }
                )
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

struct AvatarView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            AvatarView(imageUrl: URL(string: "https://avatars.githubusercontent.com/u/1165004?s=40&v=4"), size: 24)
            AvatarView(imageUrl: URL(string: "https://avatars.githubusercontent.com/u/1165004?s=40&v=4"), size: 45)
            AvatarView(imageUrl: URL(string: "https://avatars.githubusercontent.com/u/1165004?s=40&v=4"), size: 87)
        }
        VStack {
            AvatarView(size: 24)
            AvatarView(size: 45)
            AvatarView(size: 87)
        }
    }
}
