//
//  WalletConnectErrorView.swift
//  Nos
//
//  Created by Matthew Lorentz on 10/23/23.
//

import Foundation
import SwiftUI

struct WalletConnectErrorView: View {
    
    @ObservedObject var controller: SendUSBCController
    var error: Error
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                PlainText("😕")
                    .font(.system(size: 50))
                Spacer()
            }
            
            HStack {
                PlainText(.localizable.somethingWentWrong)
                    .font(.clarityTitle)
                    .foregroundColor(.primaryTxt)
                    .multilineTextAlignment(.leading)
                    .padding(0)
                Spacer()
            }
            
            HStack {
                PlainText("\(error.localizedDescription). \(String(localized: .localizable.tryAgainOrContactSupport))")
                    .font(.callout)
                    .foregroundColor(.secondaryTxt)
                Spacer()
            }
            
            Spacer()
            
            BigActionButton(title: .localizable.startOver) { 
                controller.startOver()
            }
        }
        .padding(38)
        .background(Color.appBg)
    }
}

#Preview {
    let error = SendUSBCError.developer
    var previewData = PreviewData()
    let controller = SendUSBCController(
        state: .error(error), 
        destinationAddress: "0x12389749827", 
        destinationAuthor: previewData.unsAuthor,
        dismiss: {}
    )
    
    return WalletConnectErrorView(controller: controller, error: error)
        .inject(previewData: previewData)
}
