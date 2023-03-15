//
//  SquareImage.swift
//  Nos
//
//  Created by Matthew Lorentz on 3/15/23.
//

import SwiftUI
import CachedAsyncImage

struct SquareImage: View {
    var url: URL
    
    var body: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                CachedAsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                    } else if phase.error != nil {
                        EmptyView()
                    } else {
                        ProgressView()
                    }
                }
                .aspectRatio(contentMode: .fill)
            }
            .clipShape(Rectangle())
    }
}
