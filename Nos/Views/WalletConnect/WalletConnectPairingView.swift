//
//  AuthorizationView.swift
//  DAppExample
//
//  Created by Marcel Salej on 27/09/2023.
//

import SwiftUI

struct WalletConnectPairingView: View {
    
    @ObservedObject private var viewModel = WalletConnectPairingController()
    
    private let borderWidth: CGFloat = 6
    private let cornerRadius: CGFloat = 8
    private let inDrawer = true
    
    var body: some View {
        VStack {
            PlainText("Connect your GlobaliD wallet to send USBC")
                .font(.clarityTitle)
                .foregroundColor(.primaryTxt)
                .multilineTextAlignment(.leading)
                .padding(0)
            
            PlainText("Scan the QR code or download the Global ID app to send USBC to your friends!")
                .font(.callout)
                .foregroundColor(.secondaryText)
            
            if let qrImage = viewModel.qrImage {
                qrImage
                    .interpolation(.none)
                    .resizable()
                    .frame(width: 300, height: 300)
            } else {
                ProgressView()
                    .frame(width: 300, height: 300)
                    .progressViewStyle(.circular)
                    .foregroundColor(.white)
                    .controlSize(.large)
            }
            HStack {
                Spacer()
                Button(action: { viewModel.copyDidPressed() }, label: {
                    Text("Copy QR link")
                })
                Spacer()
                Button(action: { viewModel.deeplinkPressed() }, label: {
                    Text("Open link")
                })
                Spacer()
                Button(action: { viewModel.payPressed() }, label: {
                    Text("Pay")
                })
                Spacer()
            }
        }
        .padding(.horizontal, 38)
        .background(Color.appBg)
    }
}

#Preview {
    VStack {}
        .sheet(isPresented: .constant(true)) {
            WalletConnectPairingView()
        }
}
