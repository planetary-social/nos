//
//  CreateUsernameSheet.swift
//  Nos
//
//  Created by Martin Dutra on 31/1/24.
//

import SwiftUI

struct CreateUsernameSheet: View {
    private let borderWidth: CGFloat = 6
    private let cornerRadius: CGFloat = 8
    private let inDrawer = true

    var body: some View {
        ZStack {

            // Gradient border
            LinearGradient.diagonalAccent

            // Background color
            Color.appBg
                .cornerRadius(cornerRadius, corners: inDrawer ? [.topLeft, .topRight] : [.allCorners])
                .padding(.top, borderWidth)
                .padding(.horizontal, borderWidth)
                .padding(.bottom, inDrawer ? 0 : borderWidth)

            // Content
            VStack(alignment: .leading) {
                Text("New".uppercased())
                    .padding(5)
                    .font(.clarityCaption)
                    .foregroundStyle(Color.white)
                    .background {
                        Color.secondaryTxt
                            .cornerRadius(4, corners: .allCorners)
                    }
                    .padding(.leading, 40)
                    .padding(.bottom, 20)
                    .padding(.top, 40)
                Text(.localizable.claimUniqueUsernameTitle)
                    .font(.clarityTitle)
                    .foregroundStyle(Color.primaryTxt)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 20)
                Text(
                    .localizable.claimUniqueUsernameDescription
                )
                .font(.clarity)
                .foregroundStyle(Color.secondaryTxt)
                .padding(.horizontal, 40)
                Spacer(minLength: 0)
                BigActionButton(title: .localizable.setUpMyUsername, action: {})
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
            }
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
        .frame(idealWidth: 320, idealHeight: 480)
        .presentationDetents([.medium])
    }
}

#Preview {
    var previewData = PreviewData()
    return VStack {}
        .sheet(isPresented: .constant(true)) {
            CreateUsernameSheet()
        }
}
