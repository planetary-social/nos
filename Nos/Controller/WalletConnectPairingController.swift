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

class WalletConnectPairingController: ObservableObject {
    private let walletConnectManager = WalletConnectManager.shared
    
    @Published var qrImage: Image?
    @Published var qrCodeValue: String?
    @Published var session: Session?
    @Published var currencyItems: [CurrencyItem] = []
    
    init() {
        walletConnectManager.onReinitiateConnection = {
            Task {
                try? await self.initiateConnectionToWC()
            }
        }
        
        walletConnectManager.onSessionInitiated = {[weak self] session in
            self?.session = session
            self?.prepareAddressList(for: session)
        }
    }
    
    func initiateConnectionToWC() async throws {
        let pairingDeeplink = try await walletConnectManager.initiateConnectionRequest()
        await MainActor.run {
            print("URI FOR QR CODE TO GENERATE \(pairingDeeplink)")
            qrCodeValue = pairingDeeplink
            qrImage = pairingDeeplink.generateQRCode()
        }
    }
    
    func copyDidPressed() {
        UIPasteboard.general.string = qrCodeValue
    }
    
    func deeplinkPressed() {
        guard let uri = qrCodeValue else { return }
        UIApplication.shared.open(URL(string: "globalid-staging://wc?uri=\(uri)")!)
    }
    
    func payPressed() {
        walletConnectManager.sendTransaction(fromAddress: "0xF847D1Ae3DF7b18755cDD277acE94164DF9ac794", toAddress: "0x3d4E120592B3936b1da2Ac888221D4Eb364b5a64", amount: "1", blockChain: .ethereum)
        UIApplication.shared.open(URL(string: "globalid-staging://")!)
    }
    
    private func prepareAddressList(for session: Session) {
        let namespaces = session.namespaces.values
        var currencyItems: [CurrencyItem] = []
        namespaces.forEach { namespace in
            let accounts = namespace.accounts
            accounts.forEach { account in
                let blockchain = account.blockchain
                let addressValue = account.address
                currencyItems.append(.init(address: addressValue,
                                           blockchain: blockchain,
                                           methods: namespace.methods.compactMap { $0 }))
            }
        }
        self.currencyItems = currencyItems
    }
}


struct CurrencyItem: Hashable {
    let address: String
    let blockchain: Blockchain
    let methods: [String]
}
