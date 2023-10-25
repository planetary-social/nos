//
//  WizardTextField.swift
//  Nos
//
//  Created by Matthew Lorentz on 9/28/23.
//

import SwiftUI
import SwiftUINavigation

struct WizardTextField: View {
    
    var text: Binding<String>
    var placeholder: String = ""
    
    var body: some View {
        PlainTextField(text: text) {
            PlainText(placeholder)
                .foregroundColor(.secondaryText)
        }
        .font(.clarityTitle2)
        .foregroundColor(.primaryTxt)
        .multilineTextAlignment(.center)
        .padding(19)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondaryAction, lineWidth: 2)
                .background(Color.textFieldBg)
        )
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    hideKeyboard()
                }
            }
        }
        .padding(.vertical, 40)
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct WizardTextField_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            WithState(initialValue: "") { text in
                WizardTextField(text: text, placeholder: "12345578")
                    .padding()
            }
        }
        .background(Color.appBg)
    }
}
