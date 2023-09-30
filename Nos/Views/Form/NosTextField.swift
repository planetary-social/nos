//
//  NosTextField.swift
//  Nos
//
//  Created by Matthew Lorentz on 9/27/23.
//

import SwiftUI
import SwiftUINavigation

struct NosTextField: View {
    
    var label: Localized
    @Binding var text: String
    @FocusState private var focus: Bool
    
    var body: some View {
        NosFormField(label: label) { 
            TextField("", text: $text)
                .textInputAutocapitalization(.none)
                .foregroundColor(.primaryTxt)
                .autocorrectionDisabled()
        }
    }
}

struct NosTextField_Previews: PreviewProvider {
    static var previews: some View {
        NosForm {
            NosFormSection(label: .profilePicture) {
                WithState(initialValue: "Alice") { text in
                    NosTextField(label: .url, text: text)
                }    
            }   
        }
    }
}
