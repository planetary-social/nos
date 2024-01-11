//
//  StoryAvatarView.swift
//  Nos
//
//  Created by Matthew Lorentz on 1/10/24.
//

import SwiftUI

/// Shows the avatar for an author in the StoryAuthorCarousel.
struct StoryAvatarView: View {
    var size: CGFloat = 70

    var author: Author
    var body: some View {
        AvatarView(imageUrl: author.profilePhotoURL, size: size)
            .padding(1.5)
            .overlay(alignment: .center) {
                Circle()
                    .stroke(LinearGradient.diagonalAccent, lineWidth: 3)
                    .frame(width: size, height: size)
            }
    }
}
