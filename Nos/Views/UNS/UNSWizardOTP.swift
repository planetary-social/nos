//
//  UNSWizardIntro.swift
//  Nos
//
//  Created by Matthew Lorentz on 9/13/23.
//

import SwiftUI
import Dependencies

struct UNSWizardOTP: View {
    
    @Dependency(\.analytics) var analytics
    @Dependency(\.unsAPI) var api
    
    @State var otpCode: String = ""
    @ObservedObject var controller: UNSWizardController
    @FocusState private var focusedField: FocusedField?

    enum FocusedField {
        case textEditor
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    UNSStepImage { Image.unsOTP.offset(x: 7, y: 5) }
                        .padding(40)
                        .padding(.top, 50)
                    
                    PlainText(.verification)
                        .font(.clarityTitle)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primaryTxt)
                        .shadow(radius: 1, y: 1)
                    
                    let phoneString = controller.phoneNumber ?? "you."
                    HighlightedText(
                        Localized.verificationDescription.text(["phone_number": phoneString]),
                        highlightedWord: phoneString,
                        highlight: LinearGradient(colors: [.primaryTxt], startPoint: .top, endPoint: .bottom),
                        textColor: .secondaryText,
                        font: .clarityMedium,
                        link: nil
                    )
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 17)
                    .padding(.horizontal, 20)
                    
                    WizardTextField(text: $otpCode, placeholder: "123456")
                        .focused($focusedField, equals: .textEditor)
                        .keyboardType(.numberPad)
                        .autocorrectionDisabled()
                    
                    Spacer()
                    
                    BigActionButton(title: .submit) {
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
        do {
            analytics.enteredUNSCode()
            try await api.verifyOTPCode(
                phoneNumber: controller.phoneNumber!,
                code: otpCode.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            otpCode = ""
            try await controller.navigateToChooseOrRegisterName()
        } catch {
            otpCode = ""
            controller.state = .error
        }
    }
}

struct UNSWizardOTP_Previews: PreviewProvider {
    
    static var previewData = PreviewData()
    @State static var controller = UNSWizardController(
        state: .enterOTP, 
        authorKey: previewData.alice.hexadecimalPublicKey!,
        phoneNumber: "+1768555451"
    )
    
    static var previews: some View {
        UNSWizardOTP(controller: controller)
    }
}
