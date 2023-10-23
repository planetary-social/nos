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
            PlainText(.connectGlobalIDTitle)
                .font(.clarityTitle)
                .foregroundColor(.primaryTxt)
                .multilineTextAlignment(.leading)
                .padding(0)
            
            PlainText(.scanTheWalletConnectQR)
                .font(.callout)
                .foregroundColor(.secondaryText)
                .padding(.vertical, 8)
            
            if let qrImage = viewModel.qrImage {
                ZStack {
                    RoundedRectangle(cornerRadius: 9)
                        .foregroundColor(.white)
                        .aspectRatio(contentMode: .fit)
                    qrImage
                        .interpolation(.none)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(4)
                }
            } else {
                ProgressView()
                    .frame(width: 300, height: 300)
                    .progressViewStyle(.circular)
                    .foregroundColor(.white)
                    .controlSize(.large)
            }
            HStack {
                Spacer()
                Button(action: { viewModel.copyLinkPressed() }, label: {
                    HighlightedText(
                        text: .copyQRLink, 
                        highlightedWord: Localized.copyQRLink.string, 
                        highlight: .verticalAccent, 
                        link: nil
                    )
                })
                Spacer()
            }
            .padding(13)
            
            BigActionButton(title: .connectGlobalID) { 
                viewModel.connectPressed()
            }
        }
        .padding(38)
        .background(Color.appBg)
    }
}

#Preview {
    WalletConnectPairingView()
}
