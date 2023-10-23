//
//  WalletConnectPairingController.swift
//  DAppExample
//
//  Created by Marcel Salej on 27/09/2023.
//

import Foundation
import SwiftUI
import WalletConnectUtils
import WalletConnectPairing
import WalletConnectRelay
import WalletConnectSign
import Auth
import Logger

let globalIDURLScheme = "globalid-staging://"

class WalletConnectPairingController: ObservableObject {
    private let walletConnectManager = WalletConnectManager.shared
    
    @Published var qrImage: Image?
    @Published var qrCodeValue: String?
    @Published var session: Session?
    
    init() {
        Task { try? await initiateConnectionToWC() }
        walletConnectManager.onReinitiateConnection = {
            Task {
                try? await self.initiateConnectionToWC()
            }
        }
        
        walletConnectManager.onSessionInitiated = {[weak self] session in
            self?.session = session
        }
    }
    
    func initiateConnectionToWC() async throws {
        let wcDeeplink = try await walletConnectManager.initiateConnectionRequest()
        let globalIDDeeplink = "\(globalIDURLScheme)wc?uri=\(wcDeeplink)"
        await MainActor.run {
            print("URI FOR QR CODE TO GENERATE \(globalIDDeeplink)")
            qrCodeValue = globalIDDeeplink
            qrImage = globalIDDeeplink.generateQRCode()
        }
    }
    
    func copyLinkPressed() {
        UIPasteboard.general.string = qrCodeValue
    }
    
    func connectPressed() {
        guard let qrCodeValue, let url = URL(string: qrCodeValue) else {
            Log.error("Could not construct URL")
            return
        }
        
        UIApplication.shared.open(url) { success in
            if !success {
                UIApplication.shared.open(
                    URL(string: "https://apps.apple.com/us/app/globalid-private-digital-id/id1439340119")!
                )
            }
        }
    }
}
