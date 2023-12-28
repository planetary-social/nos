//
//  NosTextEditor.swift
//  Nos
//
//  Created by Matthew Lorentz on 9/27/23.
//

import SwiftUI
import SwiftUINavigation

struct NosTextEditor: View {
    
    var label: LocalizedStringResource
    @Binding var text: String
    
    var body: some View {
        NosFormField(label: label) { 
            TextEditor(text: $text)
                .textInputAutocapitalization(.none)
                .foregroundColor(.primaryTxt)
                .autocorrectionDisabled()
        }
    }
}

struct NosTextEditor_Previews: PreviewProvider {
    static var previews: some View {
        NosForm {
            NosFormSection(label: .localizable.profilePicture) {
                WithState(initialValue: "Alice") { text in
                    NosTextEditor(label: .localizable.bio, text: text)
                        .scrollContentBackground(.hidden)
                        .frame(maxHeight: 200)
                }    
            }
        }
    }
}
