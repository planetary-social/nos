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
    
    enum FocusedField {
        case textEditor
    }
    
    @FocusState private var focusedField: FocusedField?
    
    var body: some View {
        VStack {
            Form {
                Section {
                    TextField(text: $context.textField) {
                        Text("+1-234-567-8910")
                            .foregroundColor(.secondaryText)
                    }
                    .foregroundColor(.primaryTxt)
                    .keyboardType(.phonePad)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .textEditor)
                    HighlightedText(
                        Localized.unsDescription.string,
                        highlightedWord: Localized.unsLearnMore.string,
                        highlight: .diagonalAccent,
                        link: URL(string: "https://universalname.space")
                    )
                } header: {
                    Localized.verifyYourIdentity.view
                        .foregroundColor(.primaryTxt)
                        .fontWeight(.heavy)
                }
                .listRowBackground(LinearGradient(
                    colors: [Color.cardBgTop, Color.cardBgBottom],
                    startPoint: .top,
                    endPoint: .bottom
                ))
            }
            .scrollContentBackground(.hidden)
            
            Spacer()
            
            BigActionButton(title: .sendCode) {
                analytics.enteredUNSPhone()
                var number = context.textField
                number = number.trimmingCharacters(in: .whitespacesAndNewlines)
                number.replace("-", with: "")
                number.replace("+", with: "")
                number = "+\(number)"
                context.phoneNumber = number
                
                context.textField = ""
                do {
                    context.state = .loading
                    try await context.api.requestOTPCode(phoneNumber: number)
                    context.state = .enterOTP
                } catch {
                    context.state = .error
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 50)
        }
        .background(Color.appBg)
    }
}

struct UNSWizardPhone_Previews: PreviewProvider {
    
    static var previewData = PreviewData()
    @State static var context = UNSWizardContext(state: .intro, authorKey: previewData.alice.hexadecimalPublicKey!)
    
    static var previews: some View {
        UNSWizardPhone(context: $context)
    }
}
