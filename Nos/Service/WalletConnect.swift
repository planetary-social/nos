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

struct SocketFactory: WebSocketFactory {
    func create(with url: URL) -> WebSocketConnecting {
        WebSocket(url: url)
    }
}

extension WebSocket: WebSocketConnecting { }

protocol WalletConnectProvidable {
    func personalSign(topic: String, message: String, address: String, blockChain: SupportedChainType) -> Request
    func getBalance(topic: String, address: String, blockChain: SupportedChainType) -> Request
    func sendTransaction(topic: String, fromAddress: String, toAddress: String, amount: String, blockChain: SupportedChainType) -> Request?
    func initialize() async throws -> String
}

struct ETHWalletConnectService: WalletConnectProvidable {
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
    
    private func prepareEthereumChains() -> [String: ProposalNamespace]  {
        let methods: Set<String> = ["eth_sendTransaction", "personal_sign", "eth_signTypedData", "eth_getBalance",]
        let blockchains: Set<Blockchain> = [SupportedChainType.ethereum.blockChainValue!, SupportedChainType.ethereum.blockChainValue!, SupportedChainType
            .universalLedger.blockChainValue!]
        let namespaces: [String: ProposalNamespace] = ["eip155": ProposalNamespace(chains: blockchains, methods: methods, events: ["any"])]
        return namespaces
    }
    
    func personalSign(topic: String, message: String, address: String, blockChain: SupportedChainType = .ethereum) -> Request {
        return Request(
            topic: topic,
            method: "personal_sign",
            params: AnyCodable(["0x" + message.data(using: .utf8)!.toHexString(), address]),
            chainId: blockChain.blockChainValue!
        )
    }
    
    func getBalance(topic: String, address: String, blockChain: SupportedChainType = .ethereum) -> Request {
        return Request(
            topic: topic,
            method: "eth_getBalance",
            params: AnyCodable([address]),
            chainId: blockChain.blockChainValue!
        )
    }
    
    func sendTransaction(topic: String,
                         fromAddress: String,
                         toAddress: String,
                         amount: String,
                         blockChain: SupportedChainType = .ethereum) -> Request? {
        let decimalValue = BigDecimal(hexString: amount)
        guard let eth = Decimal(string: decimalValue.amount ?? ""),
              let wei = Web3Utils.shared.weiFrom(ether: eth) else { return nil }
        let parameters = [Transaction(from: fromAddress,
                                      to: toAddress,
                                      data: "",
                                      gas: "0.001".toHexEncodedString(prefix: "0x"),
                                      gasPrice:  "0.001".toHexEncodedString(prefix: "0x"),
                                      value: wei.hex ?? "",
                                      nonce: "0x117")]
        
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


//class WalletConnect {
//    
//    @Published public var account: [Account] = []
//    @Published public var rejectedReason: String = ""
//    var publishers = [AnyCancellable]()
//    private var sessions = [Session]()
//    var pairingURI: String?
//    
//    static var shared = WalletConnect()
//    
//    init() {
//        let projectID = Bundle.main.infoDictionary?["WALLET_CONNECT_PROJECT_ID"] as? String ?? ""
//        Networking.configure(projectId: projectID, socketFactory: SocketFactory()) 
//        let metadata = AppMetadata(
//            name: "Nos",
//            description: "Connect your wallet to Nos to send payments to other users",
//            url: "com.verse.Nos",
//            icons: ["https://raw.githubusercontent.com/danlatorre/danlatorre.github.io/main/nos-account-logo.png"]
//        )
//        
//        WalletConnectModal.configure(
//            projectId: projectID,
//            metadata: metadata
//        )
//        Pair.configure(metadata: metadata)
//        
//        Sign.instance.sessionsPublisher
//            .receive(on: DispatchQueue.main)
//            .sink { sessions in
//                self.sessions = sessions
//            }
//            .store(in: &publishers)
//        
//        Sign.instance.sessionSettlePublisher
//            .receive(on: DispatchQueue.main)
//            .sink { session in
//                self.account = session.accounts
//            }
//            .store(in: &publishers)
//        
//        Sign.instance.sessionRejectionPublisher
//            .receive(on: DispatchQueue.main)
//            .sink(receiveValue: { (session, reason) in
//                self.rejectedReason = reason.message
//            })
//            .store(in: &publishers)
//        
//        WalletConnectModal.instance.sessionResponsePublisher
//            .receive(on: DispatchQueue.main)
//            .sink { response in
//                print(response)
//            }
//            .store(in: &publishers)
//        
//        self.sessions = WalletConnectModal.instance.getSessions()
//        _ = WalletConnectModal.instance.getPairings()
//        
//        let mainChain = [
//            "eip155": ProposalNamespace(
//                chains: [.ethereum], 
//                methods: ["eth_sendTransaction", "personal_sign", "eth_signTypedData"], 
//                events: []
//            )
//        ]
//        
//        let defaultSessionParams = SessionParams(
//            requiredNamespaces: mainChain,
//            optionalNamespaces: [:],
//            sessionProperties: nil
//        )
//        
//        Task {
//            let uri = try await Pair.instance.create()
//            try await Auth.instance.request(.authorizationClaim(), topic: uri.topic)
//            try await Sign.instance.connect(requiredNamespaces: mainChain, topic: uri.topic)
//            self.pairingURI = uri.absoluteString
//        }
////        WalletConnectModal.set(sessionParams: defaultSessionParams)
//    }
//    
//    func connect() {
//        Task { @MainActor in
//            try! await WalletConnectModal.instance.cleanup()
//            WalletConnectModal.present()
//        }
//    }
//    
//    func pay() async throws {
//        guard let latestSession = sessions.last else {
//            connect()
//            return
//        }
//        
//        let pairingTopic = latestSession.pairingTopic
//        let topic = latestSession.topic
//        let uri = try await WalletConnectModal.instance.connect(topic: pairingTopic)
//        
//        try await WalletConnectModal.instance.request(
//            params: Request(
//                topic: topic, 
//                method: "eth_sendTransaction", 
//                params: AnyCodable(
//                    EthereumTransaction(
//                        from: try EthereumAddress(hex: "0xF847D1Ae3DF7b18755cDD277acE94164DF9ac794", eip55: false),
//                        to: try EthereumAddress(hex: "0x3d4E120592B3936b1da2Ac888221D4Eb364b5a64", eip55: false)
//                    )
//                ), 
//                chainId: .ethereum
//            )
//        )
//    }
//}

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
        return RequestParams(
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
