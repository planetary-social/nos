//
//  WalletConnectSendView.swift
//  Nos
//
//  Created by Matthew Lorentz on 10/23/23.
//

import SwiftUI

struct WalletConnectSendView: View {
    
    @ObservedObject var controller: SendUSBCController
    @State var amount: String = ""
    
    var body: some View {
        VStack {
            HStack {
                PlainText(.sendUSBC)
                    .font(.clarityTitle)
                    .foregroundColor(.primaryTxt)
                    .multilineTextAlignment(.leading)
                    .padding(0)
                Spacer()
            }
            
            HStack {
                PlainText(.sendTo)
                    .font(.callout)
                    .foregroundColor(.secondaryText)
                    .padding(.vertical, 8)
                Spacer()
            }
            
            // Author card
            HStack(spacing: 0) {
                AvatarView(imageUrl: controller.destinationAuthor.profilePhotoURL, size: 38)
                    .padding(12)
                VStack(spacing: 1) {
                    HStack {
                        Text(controller.destinationAuthor.safeName)
                            .foregroundColor(.primaryTxt)
                            .bold()
                            .shadow(radius: 1, y: 1)
                        Spacer()
                    }
                    HStack(spacing: 3) {
                        Image.unsLogoDark
                        Text(controller.destinationAuthor.uns ?? "")
                            .foregroundColor(.secondaryText)
                        Spacer()
                    }
                }
                .offset(y: 1)
                Spacer()
            }
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .foregroundColor(.cardBgTop)
            )
            
            HStack {
                PlainText(.amount)
                    .font(.callout)
                    .foregroundColor(.secondaryText)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                Spacer()
            }
            
            ZStack {
                PlainTextField(text: $amount) {
                    PlainText("1,000")
                        .foregroundColor(.secondaryText)
                }
                .keyboardType(.decimalPad)
                .font(.clarityTitle2)
                .foregroundColor(.primaryTxt)
                .multilineTextAlignment(.center)
                .padding(19)
                .padding(.horizontal, 46)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondaryAction, lineWidth: 2)
                        .background(Color.textFieldBg)
                )
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button(Localized.done.string) {
                            hideKeyboard()
                        }
                    }
                }
                
                HStack {
                    Image.usbcLogo
                        .resizable()
                        .frame(width: 30, height: 30)
                        .background(
                            Circle()
                                .frame(width: 29, height: 29)
                                .foregroundColor(.usbcLogoBackground)
                            )
                        .padding(17)
                    Spacer()
                }
            }
            
            Spacer()
            
            BigActionButton(title: .sendUSBC) { 
                await submit()
            }
            
            HStack {
                Spacer()
                Button(action: { controller.startOver() }, label: {
                    HighlightedText(
                        text: .reconnectWallet, 
                        highlightedWord: Localized.reconnectWallet.string, 
                        highlight: .verticalAccent, 
                        link: nil
                    )
                })
                Spacer()
            }
            .padding(13)
        }
        .padding(38)
        .background(Color.appBg)
    }
    
    func submit() async {
        do {
            try await controller.sendPayment(amount)
        } catch {
            controller.state = .error(error)
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    var previewData = PreviewData()
    var controller = SendUSBCController(
        state: .amount, 
        destinationAddress: "0x12389749827", 
        destinationAuthor: previewData.unsAuthor
    )
    
    return WalletConnectSendView(controller: controller)
        .inject(previewData: previewData)
}
