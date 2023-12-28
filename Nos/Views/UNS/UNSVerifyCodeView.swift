//
//  UNSVerifyCodeView.swift
//  Nos
//
//  Created by Matthew Lorentz on 9/13/23.
//

import SwiftUI
import Dependencies

struct UNSVerifyCodeView: View {
    
    @Dependency(\.analytics) var analytics
    @Dependency(\.unsAPI) var api
    
    @State var verificationCode: String = ""
    @ObservedObject var controller: UNSWizardController
    @FocusState private var focusedField: FocusedField?

    enum FocusedField {
        case textEditor
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    UNSStepImage { Image.unsVerificationCode.offset(x: 7, y: 5) }
                        .padding(40)
                        .padding(.top, 50)
                    
                    PlainText(.localizable.verification)
                        .font(.clarityTitle)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primaryTxt)
                        .shadow(radius: 1, y: 1)
                    
                    let phoneString = controller.phoneNumber ?? "you."
                    HighlightedText(
                        String(localized: .localizable.verificationDescription(phoneString)),
                        highlightedWord: phoneString,
                        highlight: LinearGradient(colors: [.primaryTxt], startPoint: .top, endPoint: .bottom),
                        textColor: .secondaryTxt,
                        font: .clarityMedium,
                        link: nil
                    )
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 17)
                    .padding(.horizontal, 20)
                    
                    WizardTextField(text: $verificationCode, placeholder: "123456")
                        .focused($focusedField, equals: .textEditor)
                        .keyboardType(.numberPad)
                        .autocorrectionDisabled()
                    
                    Spacer()
                    
                    BigActionButton(title: .localizable.submit) {
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
            guard let phoneNumber = controller.phoneNumber else {
                // Shouldn't end up here
                throw UNSError.developer
            }
            
            analytics.enteredUNSCode()
            try await api.verifyPhone(
                phoneNumber: phoneNumber,
                code: verificationCode.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            verificationCode = ""
            try await controller.navigateToChooseOrRegisterName()
        } catch {
            verificationCode = ""
            controller.state = .error(error)
        }
    }
}

struct UNSVerifyCodeView_Previews: PreviewProvider {
    
    static var previewData = PreviewData()
    @State static var controller = UNSWizardController(
        state: .verificationCode, 
        authorKey: previewData.alice.hexadecimalPublicKey!,
        phoneNumber: "+1768555451"
    )
    
    static var previews: some View {
        UNSVerifyCodeView(controller: controller)
    }
}
