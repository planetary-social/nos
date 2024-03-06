//
//  ProfileEditWizard.swift
//  Nos
//
//  Created by Martin Dutra on 6/3/24.
//

import SwiftUI

protocol ProfileEditWizard: View { }

extension ProfileEditWizard {
    // swiftlint:disable identifier_name
    func WizardNavigationStack<Root: View>(@ViewBuilder root: () -> Root) -> some View {
        NavigationStack(root: root)
            .frame(idealWidth: 320, idealHeight: 480)
            .presentationDetents([.medium])
    }
    // swiftlint:enable identifier_name
}
