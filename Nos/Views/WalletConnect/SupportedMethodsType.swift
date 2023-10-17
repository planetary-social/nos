//
//  SupportedMethodsType.swift
//  DAppExample
//
//  Created by Marcel Salej on 28/09/2023.
//

import Foundation


enum SupportedMethodsType: String {
    case ethGetBalance = "eth_getBalance"
    case ethSendTransaction = "eth_sendTransaction"
    case ethSignTypedData = "eth_signTypedData"
    case personalSign = "personal_sign"

    var displayName: String {
        switch self {
        case .ethGetBalance:
            return "Get balance"
        case .ethSendTransaction:
            return "Send transaction"
        case .ethSignTypedData:
            return "Sign typed data"
        case .personalSign:
            return "Personal sign"
        }
    }
}
