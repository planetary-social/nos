//
//  UNSWizardPhoneView.swift
//  Nos
//
//  Created by Matthew Lorentz on 9/13/23.
//

import SwiftUI
import Dependencies

struct UNSWizardPhoneView: View {
    
    @ObservedObject var controller: UNSWizardController
    @Dependency(\.analytics) var analytics
    @Dependency(\.unsAPI) var api
    @State var phoneNumber: String = ""
    
    enum FocusedField {
        case textEditor
    }
    
    @FocusState private var focusedField: FocusedField?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    UNSStepImage { Image.unsPhone.offset(x: 7, y: 5) }
                        .padding(40)
                        .padding(.top, 50)
                    
                    PlainText(.localizable.registration)
                        .font(.clarityTitle)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primaryTxt)
                        .shadow(radius: 1, y: 1)
                    
                    Text(.localizable.registrationDescription)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondaryTxt)
                        .padding(.vertical, 17)
                        .padding(.horizontal, 20)
                        .shadow(radius: 1, y: 1)
                    
                    WizardTextField(text: $phoneNumber, placeholder: "+1-234-567-8910")
                        .focused($focusedField, equals: .textEditor)
                        .keyboardType(.phonePad)
                        .autocorrectionDisabled()
                    
                    Spacer()
                    
                    BigActionButton(title: .localizable.sendCode) {
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
        controller.phoneNumber = number
        self.phoneNumber = ""
        
        do {
            controller.state = .loading
            try await api.requestVerificationCode(phoneNumber: number)
            controller.state = .verificationCode
        } catch {
            controller.state = .error(error)
        } 
    }
}

struct UNSWizardPhone_Previews: PreviewProvider {
    
    static var previewData = PreviewData()
    @State static var controller = UNSWizardController(
        state: .intro, 
        authorKey: previewData.alice.hexadecimalPublicKey!
    )
    
    static var previews: some View {
        UNSWizardPhoneView(controller: controller)
    }
}
