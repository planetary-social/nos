//
//  ProfileEditSheet.swift
//  Nos
//
//  Created by Martin Dutra on 6/3/24.
//

import SwiftUI

protocol ProfileEditSheet: View { }

extension ProfileEditSheet {
    // swiftlint:disable identifier_name
    func SheetVStack<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 20, content: content)
            .padding(.horizontal, 40)
            .sheetPage()
    }
    func TitleText(_ localizedStringResource: LocalizedStringResource) -> some View {
        SwiftUI.Text(localizedStringResource)
            .sheetTitle()
    }
    func DescriptionText(_ localizedStringResource: LocalizedStringResource) -> some View {
        SwiftUI.Text(localizedStringResource)
            .sheetDescription()
    }
    func DescriptionText(_ attributedString: AttributedString) -> some View {
        SwiftUI.Text(
            attributedString
                .replacingAttributes(
                    AttributeContainer(
                        [.inlinePresentationIntent: InlinePresentationIntent.stronglyEmphasized.rawValue]
                    ),
                    with: AttributeContainer(
                        [.foregroundColor: UIColor.primaryTxt]
                    )
                )
        )
        .sheetDescription()
    }
    // swiftlint:enable identifier_name
}

fileprivate extension View {
    func sheetPage() -> some View {
        self.modifier(ProfileEditSheetPageModifier())
    }
    func sheetTitle() -> some View {
        self.modifier(ProfileEditSheetTitleModifier())
    }
    func sheetDescription() -> some View {
        self.modifier(ProfileEditSheetDescriptionModifier())
    }
}

fileprivate struct ProfileEditSheetPageModifier: ViewModifier {

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

fileprivate struct ProfileEditSheetTitleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.clarity(.bold, textStyle: .title1))
            .foregroundStyle(Color.primaryTxt)
    }
}

fileprivate struct ProfileEditSheetDescriptionModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.clarity(.medium, textStyle: .subheadline))
            .lineSpacing(5)
            .foregroundStyle(Color.secondaryTxt)
    }
}
