//
//  ClaimYourUniqueIdentitySheet.swift
//  Nos
//
//  Created by Martin Dutra on 6/3/24.
//

import SwiftUI

struct ClaimYourUniqueIdentitySheet: ProfileEditSheet {

    @Binding var isPresented: Bool

    var body: some View {
        SheetVStack {
            Spacer(minLength: 40)
            PlainText(String(localized: LocalizedStringResource.localizable.new).uppercased())
                .padding(.horizontal, 6)
                .padding(.vertical, 5)
                .font(.clarity(.bold, textStyle: .footnote))
                .foregroundStyle(Color.white)
                .background {
                    Color.secondaryTxt
                        .cornerRadius(4, corners: .allCorners)
                }
            TitleText(.localizable.claimUniqueUsernameTitle)
            DescriptionText(
                AttributedString(localized: .localizable.claimUniqueUsernameDescription)
            )

            Spacer(minLength: 0)

            NavigationLink(String(localized: LocalizedStringResource.localizable.setUpMyUsername)) {
                PickYourUsernameSheet(isPresented: $isPresented)
            }
            .buttonStyle(BigActionButtonStyle())

            Spacer(minLength: 40)
        }
    }
}

#Preview {
    Color.clear.sheet(isPresented: .constant(true)) {
        ClaimYourUniqueIdentitySheet(isPresented: .constant(true))
            .presentationDetents([.medium])
    }
}
