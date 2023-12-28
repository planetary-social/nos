//
//  SendUSBCBarButtonItem.swift
//  Nos
//
//  Created by Matthew Lorentz on 10/19/23.
//

import SwiftUI

struct SendUSBCBarButtonItem: View {
    
    var destinationAddress: USBCAddress
    var destinationAuthor: Author
    @State private var walletConnectIsPresented = false
    @State private var wizardController: SendUSBCController?
    
    var body: some View {
        Button(
            action: {
                walletConnectIsPresented = true
            },
            label: {
                HStack {
                    HStack {
                        Image.usbcLogo
                            .resizable()
                            .frame(width: 22, height: 22)
                            .background(Circle().foregroundColor(.usbcLogoBackground))
                        
                        PlainText(.localizable.send)
                            .foregroundColor(.primaryTxt)
                            .font(.subheadline)
                            .bold()                        
                            .baselineOffset(1)
                            .padding(.trailing, 2)
                    }
                    .padding(3)
                    .padding(.trailing, 4)
                }
                .background(Color.appBg)
                .cornerRadius(14)
            }
        )
        .sheet(isPresented: $walletConnectIsPresented) { 
            SendUSBCWizard(
                controller: SendUSBCController(
                    destinationAddress: destinationAddress, 
                    destinationAuthor: destinationAuthor,
                    dismiss: { walletConnectIsPresented = false }
                ) 
            )
        }
    }
}

#Preview {
    let address: USBCAddress = "0x918234"
    var previewData = PreviewData()
    
    return NavigationStack { 
        VStack {}
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarTrailing) { 
                    SendUSBCBarButtonItem(destinationAddress: address, destinationAuthor: previewData.unsAuthor)
                }
            })
    }
}
