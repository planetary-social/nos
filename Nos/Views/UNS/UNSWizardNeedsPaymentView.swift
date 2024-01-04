//
//  UNSWizardNeedsPaymentView.swift
//  Nos
//
//  Created by Matthew Lorentz on 9/13/23.
//

import SwiftUI
import Dependencies

/// Shows a screen informing the user the name they registered requires payment and gives them a link to pay.
struct UNSWizardNeedsPaymentView: View {
    
    @ObservedObject var controller: UNSWizardController
    @State var hasOpenedPortal = false
    @Dependency(\.analytics) var analytics
    @Dependency(\.unsAPI) var api
    
    var body: some View {
        VStack {
            Image.unsPremium
                .frame(width: 178, height: 178)
                .padding(40)
                .padding(.top, 50)
            
            PlainText(.localizable.premiumName)
                .font(.clarityTitle)
                .multilineTextAlignment(.center)
                .foregroundColor(.primaryTxt)
                .readabilityPadding()
                .shadow(radius: 1, y: 1)
            
            Text(hasOpenedPortal ? .localizable.returnToChooseName : .localizable.premiumNameDescription)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondaryTxt)
                .readabilityPadding()
                .padding(.vertical, 17)
                .padding(.horizontal, 20)
            
            Spacer()
            
            if case let .needsPayment(url) = controller.state, !hasOpenedPortal {
                VStack {
                    Button { 
                        controller.state = .chooseName
                    } label: { 
                        HighlightedText(
                            text: .localizable.goBackAndRegister, 
                            highlightedWord: String(localized: .localizable.registerADifferentName), 
                            highlight: LinearGradient(colors: [.primaryTxt], startPoint: .top, endPoint: .bottom), 
                            textColor: .secondaryTxt,
                            font: .clarityMedium,
                            link: nil
                        )
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 20)
                    
                    BigActionButton(title: .localizable.registerPremiumName, backgroundGradient: .gold) {
                        await UIApplication.shared.open(url)
                        hasOpenedPortal = true
                    }
                    .padding(.bottom, 41)
                }
            } else {
                BigActionButton(title: .localizable.next) {
                    do {
                        try await controller.navigateToChooseOrRegisterName()
                    } catch {
                        controller.state = .error(error)
                    }
                }
                .padding(.bottom, 41)
            }
        }
        .padding(.horizontal, 38)
        .readabilityPadding()
        .background(Color.appBg)
    }
}

#Preview {
    
    var previewData = PreviewData()
    @State var controller = UNSWizardController(
        state: .needsPayment(URL(string: "https://www.universalname.space/name/frankie")!), 
        authorKey: previewData.alice.hexadecimalPublicKey!,
        nameRecord: UNSNameRecord(name: "frankie", id: "1")
    )
    
    return UNSWizardNeedsPaymentView(controller: controller)
}
