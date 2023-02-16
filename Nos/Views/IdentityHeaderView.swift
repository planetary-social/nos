//
//  IdentityViewHeader.swift
//  Planetary
//
//  Created by Martin Dutra on 11/11/22.
//  Copyright © 2022 Verse Communications Inc. All rights reserved.
//

import SwiftUI

struct IdentityHeaderView: View {

    var identity: Author

    private var shouldShowBio: Bool {
        if let about = identity.about {
            return about.isEmpty == false
        }
        return false
    }

    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                HStack(alignment: .top, spacing: 18) {
                    ZStack(alignment: .bottomTrailing) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.body)
                            .frame(width: 87, height: 87)
                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 99)
                                    .stroke(LinearGradient.diagonalAccent, lineWidth: 3)
                            )
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Spacer()
                        Text(identity.displayName)
                            .lineLimit(1)
                            .font(.title3.weight(.semibold))
                            .foregroundColor(Color.primaryTxt)
                        // TODO: Put follow button here
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding()
                .frame(maxWidth: .infinity, alignment: .topLeading)
                if shouldShowBio {
                    BioView(bio: identity.about)
                }
            }
            .frame(maxWidth: 500)
        }
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color.profileBgTop, Color.profileBgBottom],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .compositingGroup()
        .shadow(color: .profileShadow, radius: 10, x: 0, y: 4)
    }
}

// swiftlint:disable force_unwrapping
struct IdentityHeaderView_Previews: PreviewProvider {
    
    static var persistenceController = PersistenceController.preview
    static var previewContext = persistenceController.container.viewContext
    
    static var author: Author {
        let author = Author(context: previewContext)
        // TODO: derive from private key
        author.hexadecimalPublicKey = KeyFixture.pubKeyHex
        return author
    }
    
    static var previews: some View {
        Group {
            IdentityHeaderView(identity: author)
        }
        .padding()
        .background(Color.cardBackground)
    }
}
