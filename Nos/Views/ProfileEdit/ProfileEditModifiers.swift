//
//  ProfileEditModifiers.swift
//  Nos
//
//  Created by Martin Dutra on 5/3/24.
//

import SwiftUI

struct ProfileEditSheetPageModifier: ViewModifier {

    private let borderWidth: CGFloat = 6
    private let cornerRadius: CGFloat = 8
    private let inDrawer = true

    func body(content: Content) -> some View {
        ZStack {
            // Gradient border
            LinearGradient.diagonalAccent

            // Background color
            LinearGradient.nip05
                .cornerRadius(cornerRadius, corners: inDrawer ? [.topLeft, .topRight] : [.allCorners])
                .padding(.top, borderWidth)
                .padding(.horizontal, borderWidth)
                .padding(.bottom, inDrawer ? 0 : borderWidth)

            content
                .background {
                    VStack {
                        HStack(alignment: .top) {
                            Spacer()
                            Image.atSymbol
                                .aspectRatio(2, contentMode: .fit)
                                .blendMode(.softLight)
                                .scaleEffect(2)
                        }
                        .offset(x: 28, y: 20)
                        Spacer()
                    }
                }
                .padding(.top, borderWidth)
                .padding(.horizontal, borderWidth)
                .padding(.bottom, inDrawer ? 0 : borderWidth)
                .clipShape(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                )
        }
        .edgesIgnoringSafeArea(.bottom)
        .navigationBarBackButtonHidden()
    }
}

struct ProfileEditSheetTitleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.clarity(.bold, textStyle: .title1))
            .foregroundStyle(Color.primaryTxt)
    }
}

struct ProfileEditSheetDescriptionModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.clarity(.medium, textStyle: .subheadline))
            .lineSpacing(5)
            .foregroundStyle(Color.secondaryTxt)
    }
}

extension View {
    func profileEditSheetPage() -> some View {
        self.modifier(ProfileEditSheetPageModifier())
    }
    func profileEditSheetTitle() -> some View {
        self.modifier(ProfileEditSheetTitleModifier())
    }
    func profileEditSheetDescription() -> some View {
        self.modifier(ProfileEditSheetDescriptionModifier())
    }
}
