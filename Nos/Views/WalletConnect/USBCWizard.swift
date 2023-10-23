//
//  USBCWizard.swift
//  Nos
//
//  Created by Matthew Lorentz on 10/18/23.
//

import SwiftUI
import Combine
import Dependencies

enum USBCWizardStep {
    case pair, amount, success, error, loading
}

class USBCWizardController: ObservableObject {
    @Dependency(\.currentUser) private var currentUser
    
    @Published var step: USBCWizardStep
    @Published var fromAddress: USBCAddress?
    @Published var toAddress: USBCAddress?
    
    private var cancellables = [AnyCancellable]()
    
    let walletConnectManager = WalletConnectManager.shared
    
    init(step: USBCWizardStep = .loading) {
        self.step = step
        
        walletConnectManager.onSessionInitiated = { [weak self] _ in 
            Task { @MainActor [weak self] in
                self?.updateStep()
            }
        }
        
        Task {
            try! await walletConnectManager.initiateConnectionRequest()
            await updateStep()
        }
        
        currentUser.$usbcAddress.sink { [weak self] newAddress in
            self?.fromAddress = newAddress
        }
        .store(in: &cancellables)
    }
    
    @MainActor func updateStep() {
        if let session = walletConnectManager.getAllSessions().last {
            walletConnectManager.saveInitiatedSessions(sessions: session)
            step = .amount
        } else {
            step = .pair
        }
    }
}

struct USBCWizard: View {
    
    @ObservedObject private var controller = USBCWizardController()
    
    private let borderWidth: CGFloat = 6
    private let cornerRadius: CGFloat = 8
    private let inDrawer = true
    
    var toAddress: USBCAddress
    @State var amount: String = ""
    
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
                case .loading:
                    Text("Loading")
                case .pair:
                    WalletConnectPairingView()
                case .amount:
                    VStack {
                        Text("Enter amount")
                        WizardTextField(text: $amount)
                        BigActionButton(title: .submit) { 
                            guard let doubleAmount = Double(amount),
                                  let fromAddress = controller.fromAddress else {
                                print("error")
                                controller.step = .error
                                return
                            }
                            controller.walletConnectManager.sendTransaction(fromAddress: fromAddress, toAddress: toAddress, amount: amount, blockChain: .universalLedger)
                            // TODO: open GlobaliD
                        }
                    }
                case .error:
                    Text("Error")
                case .success:
                    Text("Success")
                }
            }
            .background(Color.appBg)
            .padding(.top, borderWidth)
            .padding(.horizontal, borderWidth)
            .padding(.bottom, inDrawer ? 0 : borderWidth)
            .clipShape(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
        }
        .edgesIgnoringSafeArea(.bottom)
        .frame(idealWidth: 320, idealHeight: 480)
        .presentationDetents([.medium])
    }
}

#Preview {
    VStack {}
        .sheet(isPresented: .constant(true)) {
            USBCWizard(toAddress: "0x1234")
        }
}
