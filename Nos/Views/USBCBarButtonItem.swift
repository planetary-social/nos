//
//  USBCBarButtonItem.swift
//  Nos
//
//  Created by Matthew Lorentz on 10/19/23.
//

import SwiftUI

struct USBCBarButtonItem: View {
    
    @Binding var address: USBCAddress?
    @Binding var balance: Double?
    @State private var walletConnectIsPresented = false
    
    var body: some View {
        Button(
            action: {
                walletConnectIsPresented = true
            },
            label: {
                HStack {
                    if let balance {
                        Text("USBC")
                        Text(String(format: "%.2f", balance))
                    } else {
                        Text("Send USBC")
                    }
                }
            }
        )
        .sheet(isPresented: $walletConnectIsPresented) { 
            USBCWizard()
        }
    }
}

#Preview("Logged in User") {
    @State var address: USBCAddress? = "0x918234"
    @State var balance: Double? = 100.23109184091284
    
    return NavigationStack { 
        VStack {}
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarTrailing) { 
                    USBCBarButtonItem(address: $address, balance: $balance)
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
                    USBCBarButtonItem(address: $address, balance: $balance)
                }
            })
    }
}
