//
//  USBCBalanceBarButtonItem.swift
//  Nos
//
//  Created by Matthew Lorentz on 10/23/23.
//

import SwiftUI

struct USBCBalanceBarButtonItem: View {
    
    @Binding var balance: Double?
    
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
                // TODO:
            },
            label: {
                HStack {
                    HStack {
                        Image.usbcLogo
                            .resizable()
                            .frame(width: 22, height: 22)
                            .background(Circle().foregroundColor(.usbcLogoBackground))
                        
                        PlainText(formattedBalance)
                            .font(.subheadline)
                            .foregroundColor(.primaryTxt)
                            .bold()
                    }
                    .padding(3)
                    .padding(.trailing, 4)
                }
                .background(Color.appBg)
                .cornerRadius(14)
            }
        )
    }
}

#Preview {
    @State var balance: Double? = 10_028_732.23109184091284
    
    return NavigationStack { 
        VStack {}
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarTrailing) { 
                    USBCBalanceBarButtonItem(balance: $balance)
                }
            })
    }
}
