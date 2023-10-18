//
//  USBCWizard.swift
//  Nos
//
//  Created by Matthew Lorentz on 10/18/23.
//

import SwiftUI

enum USBCWizardStep {
    case pair, amount, success, error, loading
}

class USBCWizardController: ObservableObject {
    @Published var step = USBCWizardStep.pair
}

struct USBCWizard: View {
    
    @ObservedObject private var controller = USBCWizardController()
    
    private let borderWidth: CGFloat = 6
    private let cornerRadius: CGFloat = 8
    private let inDrawer = true
    
    var body: some View {
        ZStack {
            
            // Gradient border
            LinearGradient.diagonalAccent
            
            // Background color
            Color.menuBorderColor
                .cornerRadius(cornerRadius, corners: inDrawer ? [.topLeft, .topRight] : [.allCorners])
                .padding(.top, borderWidth)
                .padding(.horizontal, borderWidth)
                .padding(.bottom, inDrawer ? 0 : borderWidth)
            
            // Content
            VStack {
                switch controller.step {
                case .pair:
                    WalletConnectPairingView()
                default:
                    Text("not implemented")
                }
            }
            .padding(.top, borderWidth)
            .padding(.horizontal, borderWidth)
            .padding(.bottom, inDrawer ? 0 : borderWidth)
            .clipShape(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
        }
        .edgesIgnoringSafeArea(.bottom)
        .frame(idealWidth: 320, idealHeight: 480)
    }
}

#Preview {
    VStack {}
        .sheet(isPresented: .constant(true)) {
            USBCWizard()
        }
}
