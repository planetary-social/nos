//
//  AvatarView.swift
//  Nos
//
//  Created by Shane Bielefeld on 2/17/23.
//

import SwiftUI
import CachedAsyncImage

extension URLCache {
    // TODO: allow the user to clear this
    static let imageCache = URLCache(memoryCapacity: 512 * 1000 * 1000, diskCapacity: 1 * 1000 * 1000 * 1000)
}

struct AvatarView: View {
    
    var imageUrl: URL?
    var size: CGFloat
    
    var body: some View {
        Group {
            let emptyAvatar = Image.emptyAvatar
                .resizable()
                .renderingMode(.original)
            
            if let imageURL = imageUrl {
                CachedAsyncImage(url: imageURL, urlCache: .imageCache) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                    } else if phase.error != nil {
                        emptyAvatar
                    } else {
                        ProgressView()
                    }
                }
            } else {
                emptyAvatar
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
