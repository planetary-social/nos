//
//  UpdateUsernameView.swift
//  Nos
//
//  Created by Martin Dutra on 6/2/24.
//

import SwiftUI

struct UpdateUsernameView: View {

    @State private var nip05: String = ""

    var body: some View {
        NosForm {
            NosFormSection(label: .localizable.profilePicture) {
                NosTextField(label: .localizable.url, text: $nip05)
                NosTextField(label: .localizable.url, text: $nip05)
            }
        }
    }
}

#Preview {
    UpdateUsernameView()
}
