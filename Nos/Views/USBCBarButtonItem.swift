//
//  USBCBarButtonItem.swift
//  Nos
//
//  Created by Matthew Lorentz on 10/19/23.
//

import SwiftUI

struct USBCBarButtonItem: View {
    
    var address: USBCAddress?
    @Binding var balance: Double?
    @State private var walletConnectIsPresented = false
    
    var formattedBalance: String {
        let errorText = "~"
        guard let balance else {
            return errorText
        }
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.locale = Locale.current
        numberFormatter.usesGroupingSeparator = true
        numberFormatter.currencySymbol = ""
        
        let formattedBalance = numberFormatter.string(from: NSNumber(value: balance))
        return formattedBalance ?? errorText
    }
    
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
                            .background(Circle().foregroundColor(Color(hex: "#19072C")))
                        
                        if let balance {
                            PlainText(formattedBalance)
                                .font(.subheadline)
                                .foregroundColor(.primaryTxt)
                                .bold()
                        } else {
                            PlainText(.send)
                                .foregroundColor(.primaryTxt)
                                .font(.subheadline)
                                .bold()                        
                                .baselineOffset(1)
                                .padding(.trailing, 2)
                        }
                    }
                    .padding(3)
                    .padding(.trailing, 4)
                }
                .background(Color.appBg)
                .cornerRadius(14)
            }
        )
        .sheet(isPresented: $walletConnectIsPresented) { 
            if let toAddress = address {
                USBCWizard(toAddress: toAddress)
            }
        }
    }
}

#Preview("Logged in User") {
    @State var address: USBCAddress? = "0x918234"
    @State var balance: Double? = 10_028_732.23109184091284
    
    return NavigationStack { 
        VStack {}
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarTrailing) { 
                    USBCBarButtonItem(address: address, balance: $balance)
                }
            })
    }
}

#Preview("Other user") {
    @State var address: USBCAddress? = "0x918234"
    @State var balance: Double? 
    
    return NavigationStack { 
        VStack {}
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarTrailing) { 
                    USBCBarButtonItem(address: address, balance: $balance)
                }
            })
    }
}
