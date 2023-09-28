//
//  UNSWizardPhone.swift
//  Nos
//
//  Created by Matthew Lorentz on 9/13/23.
//

import SwiftUI
import Dependencies

struct UNSWizardPhone: View {
    
    @Binding var context: UNSWizardContext
    @Dependency(\.analytics) var analytics
    @State var phoneNumber: String = ""
    
    enum FocusedField {
        case textEditor
    }
    
    @FocusState private var focusedField: FocusedField?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    Image.unsPhone
                        .frame(width: 178, height: 178)
                        .padding(40)
                        .padding(.top, 50)
                    
                    PlainText(.registration)
                        .font(.clarityTitle)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primaryTxt)
                        .shadow(radius: 1, y: 1)
                    
                    Text(.registrationDescription)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondaryText)
                        .padding(.vertical, 17)
                        .padding(.horizontal, 20)
                        .shadow(radius: 1, y: 1)
                    
                    WizardTextField(text: $phoneNumber, placeholder: "+1-234-567-8910")
                        .focused($focusedField, equals: .textEditor)
                        .keyboardType(.phonePad)
                        .autocorrectionDisabled()
                    
                    Spacer()
                    
                    BigActionButton(title: .sendCode) {
                        await submit()
                    }
                    .padding(.bottom, 41)
                }
                .padding(.horizontal, 38)
                .readabilityPadding()
            }
            .background(Color.appBg)
            .onAppear {
                focusedField = .textEditor
            }
        }
    }
    
    private func submit() async {
        analytics.enteredUNSPhone()
        var number = phoneNumber
        number = number.trimmingCharacters(in: .whitespacesAndNewlines)
        number.replace("-", with: "")
        number.replace("+", with: "")
        number = "+\(number)"
        context.phoneNumber = number
        self.phoneNumber = ""
        
        do {
            context.state = .loading
            try await context.api.requestOTPCode(phoneNumber: number)
            context.state = .enterOTP
        } catch {
            context.state = .error
        } 
    }
}

struct UNSWizardPhone_Previews: PreviewProvider {
    
    static var previewData = PreviewData()
    @State static var context = UNSWizardContext(state: .intro, authorKey: previewData.alice.hexadecimalPublicKey!)
    
    static var previews: some View {
        UNSWizardPhone(context: $context)
    }
}
