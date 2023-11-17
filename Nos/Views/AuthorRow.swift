//
//  AuthorRow.swift
//  Nos
//
//  Created by Martin Dutra on 3/4/23.
//

import SwiftUI

/// This view displays the information we have for an author suitable for being used in a list or grid.
struct AuthorRow: View {

    @ObservedObject var author: Author

    @Environment(\.managedObjectContext) private var viewContext
    @Environment(CurrentUser.self) private var currentUser

    var didTapGesture: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                Button {
                    didTapGesture?()
                } label: {
                    HStack(alignment: .center) {
                        AvatarView(imageUrl: author.profilePhotoURL, size: 24)
                        Text(author.safeName)
                            .lineLimit(1)
                            .font(.subheadline)
                            .foregroundColor(Color.primaryTxt)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if author.muted {
                            Text(Localized.muted.string)
                                .font(.subheadline)
                                .foregroundColor(Color.secondaryText)
                        }
                        Spacer()
                    }
                }
            }
            .padding(10)
            BeveledSeparator()
        }
        .background(
            LinearGradient(
                colors: [Color.cardBgTop, Color.cardBgBottom],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .listRowInsets(EdgeInsets())
        .cornerRadius(cornerRadius)
    }

    var cornerRadius: CGFloat { 15 }
}
