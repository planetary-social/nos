//
//  CreateUsernameSheet.swift
//  Nos
//
//  Created by Martin Dutra on 31/1/24.
//

import SwiftUI

struct CreateUsernameSheet: View {

    var action: (() -> Void)?

    var body: some View {
        NavigationStack {
            // Content
            VStack(alignment: .leading, spacing: 20) {
                Spacer(minLength: 40)
                Text("New".uppercased())
                    .padding(5)
                    .font(.clarityCaption)
                    .foregroundStyle(Color.white)
                    .background {
                        Color.secondaryTxt
                            .cornerRadius(4, corners: .allCorners)
                    }
                Text(.localizable.claimUniqueUsernameTitle)
                    .font(.clarityTitle)
                    .foregroundStyle(Color.primaryTxt)
                Text(
                    .localizable.claimUniqueUsernameDescription
                )
                .font(.clarity)
                .foregroundStyle(Color.secondaryTxt)

                Spacer(minLength: 0)

                Button {
                    action?()
                } label: {
                    PlainText(.localizable.getMyHandle)
                        .font(.clarityBold)
                        .transition(.opacity)
                        .font(.headline)
                }
                .buttonStyle(BigActionButtonStyle())

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 40)
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
            .sheetPage()
        }
        .frame(idealWidth: 320, idealHeight: 480)
        .presentationDetents([.medium])
    }
}

fileprivate struct SheetPageModifier: ViewModifier {

    private let borderWidth: CGFloat = 6
    private let cornerRadius: CGFloat = 8
    private let inDrawer = true

    func body(content: Content) -> some View {
        ZStack {
            // Gradient border
            LinearGradient.diagonalAccent

            // Background color
            Color.appBg
                .cornerRadius(cornerRadius, corners: inDrawer ? [.topLeft, .topRight] : [.allCorners])
                .padding(.top, borderWidth)
                .padding(.horizontal, borderWidth)
                .padding(.bottom, inDrawer ? 0 : borderWidth)

            content
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

fileprivate extension View {
    func sheetPage() -> some View {
        self.modifier(SheetPageModifier())
    }
}

#Preview {
    var previewData = PreviewData()
    return VStack {}
        .sheet(isPresented: .constant(true)) {
            CreateUsernameSheet()
        }
}
