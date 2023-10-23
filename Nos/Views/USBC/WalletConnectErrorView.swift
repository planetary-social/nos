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
        VStack {
            HStack {
                PlainText("😕")
                    .font(.system(size: 50))
                Spacer()
            }
            
            HStack {
                PlainText(.somethingWentWrong)
                    .font(.clarityTitle)
                    .foregroundColor(.primaryTxt)
                    .multilineTextAlignment(.leading)
                    .padding(0)
                Spacer()
            }
            
            HStack {
                PlainText("\(error.localizedDescription). \(Localized.tryAgainOrContactSupport.string)")
                    .font(.callout)
                    .foregroundColor(.secondaryText)
                    .padding(.vertical, 8)
                Spacer()
            }
            
            Spacer()
            
            BigActionButton(title: .startOver) { 
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
    var controller = SendUSBCController(
        state: .error(error), 
        destinationAddress: "0x12389749827", 
        destinationAuthor: previewData.unsAuthor
    )
    
    return WalletConnectErrorView(controller: controller, error: error)
        .inject(previewData: previewData)
}
