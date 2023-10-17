//
//  MethodDetailViewModel.swift
//  DAppExample
//
//  Created by Marcel Salej on 28/09/2023.
//

import Foundation
import WalletConnectSign
import UIKit

class MethodDetailViewModel: ObservableObject {

    @Published var methodType: SupportedMethodsType
    @Published var personalSignMessage: String = "Type your message to sign here"
    @Published var senderAddres: String = ""
    @Published var sendAmount: String = ""
    @Published var transactionId: String = ""
    @Published var errorMessage: String?
    @Published var supportedChainType: SupportedChainType

    private let walletConnectManager = WalletConnectManager.shared
    private let session: Session
    private let currencyItem: CurrencyItem
    private let selectedMethod: SupportedMethodsType

    private var address: String {
        return currencyItem.address
    }

    init(session: Session, currencyItem: CurrencyItem, selectedMethod: SupportedMethodsType) {
        self.session = session
        self.currencyItem = currencyItem
        self.selectedMethod = selectedMethod

        methodType = selectedMethod
        let chainType = SupportedChainType.allCases.first(where: { currencyItem.blockchain == $0.blockChainValue })
        self.supportedChainType = chainType ?? .ethereum
    }

    func getAddressBalance() {
        walletConnectManager.getBalance(address: address, blockChain: supportedChainType)
    }

    func sendTransaction() {
        // Result
        walletConnectManager.onSessionResponse = { [weak self] response in
            switch response.result {
            case .response(let value):
                do {
                    let string = try value.get(String.self)
                    self?.transactionId = string
                } catch {
                    self?.errorMessage = "There has been an exception at parsing:  \n  \n ".appending(error.localizedDescription)
                }
            case .error(let error):
                self?.errorMessage = "There has been an exception:  \n  \n ".appending(error.localizedDescription)
            }
        }
        guard senderAddres.count > 0, sendAmount.count > 0 else { return }
        walletConnectManager.sendTransaction(fromAddress: address,
                                             toAddress: senderAddres,
                                             amount: sendAmount,
                                             blockChain: supportedChainType)
        
        // Link back to app.
        UIApplication.shared.open(URL(string: "globalid-staging//")!)
    }

    func signTypedData() {

    }

    func personalSign() {
        walletConnectManager.onSessionResponse = { [weak self] response in
            switch response.result {
            case .response(let value):
                do {
                    let string = try value.get(String.self)
                    let signature = CacaoSignature(t: .eip191, s: string.deleting0x())

                } catch {
                    self?.errorMessage = "There has been an exception at parsing:  \n  \n ".appending(error.localizedDescription)
                }
            case .error(let error):
                self?.errorMessage = "There has been an exception:  \n  \n ".appending(error.localizedDescription)
            }
        }
        walletConnectManager.personalSign(message: personalSignMessage,
                                          address: address,
                                          blockChain: supportedChainType)
    }
}
