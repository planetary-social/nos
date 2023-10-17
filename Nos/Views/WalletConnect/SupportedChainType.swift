//
//  SupportedChainType.swift
//  DAppExample
//
//  Created by Marcel Salej on 28/09/2023.
//

import Foundation
import WalletConnectUtils


enum SupportedChainType: CaseIterable {
    case ethereum
    case universalLedger


    var displayValue: String {
        switch self {
        case .ethereum:
            return WalletConnectManager.shared.testMode ? "Ethereum Sepolia" : "Ethereum"
        case .universalLedger:
            return WalletConnectManager.shared.testMode ? "Universal ledger testnet" : "Universal ledger"
        }
    }

    var blockChainId: String {
        switch self {
        case .ethereum, .universalLedger:
            return "eip155"
        }
    }

    var blockChainValue: Blockchain? {
        switch self {
        case .ethereum:
            return WalletConnectManager.shared.testMode ?  Blockchain("\(self.blockChainId):11155111") : Blockchain("\(self.blockChainId):1")
        case .universalLedger:
            return WalletConnectManager.shared.testMode ?  Blockchain("\(self.blockChainId):20231") : Blockchain("\(self.blockChainId):2024")
        }
    }
}
