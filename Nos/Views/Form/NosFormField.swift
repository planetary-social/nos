//
//  NosFormField.swift
//  Nos
//
//  Created by Matthew Lorentz on 9/28/23.
//

import SwiftUI
import SwiftUINavigation

struct NosFormField<Control: View>: View {
    
    let control: Control
    let label: LocalizedStringResource
    @FocusState private var focus: Bool
    
    init(label: LocalizedStringResource, @ViewBuilder builder: () -> Control) {
        self.label = label
        self.control = builder()
    }
    
    var body: some View {
        VStack {
            HStack {
                Text(label)
                    .foregroundColor(.secondaryTxt)
                    .fontWeight(.medium)
                    .font(.clarityFootnote)
                Spacer()
            }
            
            control
                .accessibilityLabel(String(localized: label))
                .focused($focus)
        }
        .padding(16)
        .contentShape(Rectangle())
        .onTapGesture {
            focus = true
        }
    }
}

struct NosFormField_Previews: PreviewProvider {
    static var previews: some View {
        NosForm {
            NosFormSection(label: .localizable.profileTitle) {
                WithState(initialValue: "") { text in
                    NosFormField(label: .localizable.about) {
                        TextField("", text: text)
                            .textInputAutocapitalization(.none)
                            .foregroundColor(.primaryTxt)
                            .autocorrectionDisabled()
                    }
                }
            }
        }
    }
}
