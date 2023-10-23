//
//  SupportedChainType.swift
//  DAppExample
//
//  Created by Marcel Salej on 28/09/2023.
//

import Foundation
import WalletConnectUtils

enum WalletConnectChain: CaseIterable {
    case ethereum
    case universalLedger

    var displayValue: String {
        switch self {
        case .ethereum:
            return "Ethereum"
        case .universalLedger:
            return "Universal ledger"
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
            return Blockchain("\(self.blockChainId):1")
        case .universalLedger:
            return Blockchain("\(self.blockChainId):2024")
        }
    }
}
