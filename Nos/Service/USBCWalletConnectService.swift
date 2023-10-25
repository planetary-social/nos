//
//  WalletConnect.swift
//  Nos
//
//  Created by Matthew Lorentz on 9/19/23.
//

import Foundation
import Logger
import StarscreamOld
import Auth
import WalletConnectModal
import WalletConnectRelay
import WalletConnectNetworking
import Web3Wallet
import Web3
import Combine
import UIKit

/// A protocol for different adapters that abstract the WalletConnect protocol. The idea is that we might have different
/// ones for different cryptocurrencies.
protocol WalletConnectProvidable {
    func initialize() async throws -> String
    func sendTransaction(
        topic: String, 
        fromAddress: String, 
        toAddress: String, 
        amount: String, 
        blockChain: WalletConnectChain
    ) -> Request?
}

/// A service that helps us interact with a USBC crypto wallet via the WalletConnect protocol. 
struct USBCWalletConnectService: WalletConnectProvidable {
    
    func initialize() async throws -> String {
        let metadata = AppMetadata(
            name: "Nos",
            description: "Connect your wallet to Nos to send payments to other users",
            url: "com.verse.Nos",
            icons: ["https://raw.githubusercontent.com/danlatorre/danlatorre.github.io/main/nos-account-logo.png"]
        )
        let projectID = Bundle.main.infoDictionary?["WALLET_CONNECT_PROJECT_ID"] as? String ?? ""
        Networking.configure(projectId: projectID, socketFactory: SocketFactory()) 
        Pair.configure(metadata: metadata)
        Auth.configure(crypto: WalletConnectCryptoProvider())
        let uri = try await Pair.instance.create()
        try await Auth.instance.request(.authorizationClaim(), topic: uri.topic)
        try await Sign.instance.connect(requiredNamespaces: prepareEthereumChains(), topic: uri.topic)
        return uri.absoluteString
    }
    
    private func prepareEthereumChains() -> [String: ProposalNamespace] {
        let methods: Set<String> = ["eth_sendTransaction", "personal_sign", "eth_signTypedData", "eth_getBalance"]
        let blockchains: Set<Blockchain> = [WalletConnectChain.universalLedger.blockChainValue!]
        let namespaces: [String: ProposalNamespace] = [
            "eip155": ProposalNamespace(chains: blockchains, methods: methods, events: ["any"])
        ]
        return namespaces
    }
    
    /// Sends a request for a transaction to be signed to the wallet app via WalletConnect's websockets.
    func sendTransaction(
        topic: String,
        fromAddress: String,
        toAddress: String,
        amount: String,
        blockChain: WalletConnectChain = .ethereum
    ) -> Request? {
        let decimalValue = BigDecimal(hexString: amount)
        guard let ethereum = Decimal(string: decimalValue.amount ?? ""),
            let wei = Web3Utils.shared.weiFrom(ether: ethereum) else { 
            return nil 
        }
        let parameters = [
            Transaction(
                from: fromAddress,
                to: toAddress,
                data: "",
                gas: "0.001".toHexEncodedString(prefix: "0x"),
                gasPrice: "0.001".toHexEncodedString(prefix: "0x"),
                value: wei.hex ?? "",
                nonce: "0x117"
            )
        ]
        
        return Request(
            topic: topic,
            method: "eth_sendTransaction",
            params: AnyCodable(parameters),
            chainId: blockChain.blockChainValue!
        )
    }
}

struct Transaction: Codable {
    let from, to, data, gas: String
    let gasPrice, value, nonce: String
}

// swiftlint:disable identifier_name
extension RequestParams {
    static func authorizationClaim(
        domain: String = "global.id",
        chainId: String = "eip155:11155111",
        nonce: String = "32891756",
        aud: String = "https://service.invalid/login",
        nbf: String? = nil,
        exp: String? = nil,
        statement: String? = "I accept the GlobalId Terms of Service: https://global.id/tos",
        requestId: String? = nil,
        resources: [String]? = []
    ) -> RequestParams {
        RequestParams(
            domain: domain,
            chainId: chainId,
            nonce: nonce,
            aud: aud,
            nbf: nbf,
            exp: exp,
            statement: statement,
            requestId: requestId,
            resources: resources
        )
    }
}
// swiftlint:enable identifier_name

/// Needed for WalletConnect to use websockets
struct SocketFactory: WebSocketFactory {
    func create(with url: URL) -> WebSocketConnecting {
        WebSocket(url: url)
    }
}

extension WebSocket: WebSocketConnecting { }
