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
import CryptoSwift
import Web3
import Combine
import UIKit

//class WalletConnectSocket: WebSocketConnecting {
//    
//    init(request: URLRequest) {
//        self.request = request
//        starscreamSocket = WebSocket(request: request)
//        starscreamSocket.request.setValue(nil, forHTTPHeaderField: "Origin")
//        starscreamSocket.onEvent = { [weak self] event in
//            switch event {
//            case .connected(_):
//                self?.isConnected = true
//                self?.onConnect?()
//            case .disconnected(_, _):
//                self?.isConnected = false
//                self?.onDisconnect?(nil)
//            case .text(let text):
//                self?.onText?(text)
//            case .binary, .pong, .ping, .viabilityChanged, .reconnectSuggested:
//                break
//            case .error(let error):
//                Log.optional(error)
//                break
//            case .cancelled, .peerClosed:
//                self?.isConnected = false
//            }
//        }
//    }
//    
//    private var starscreamSocket: WebSocket
//    
//    var isConnected: Bool = false
//    
//    var onConnect: (() -> Void)?
//    
//    var onDisconnect: ((Error?) -> Void)?
//    
//    var onText: ((String) -> Void)?
//    
//    var request: URLRequest
//    
//    func connect() {
//        starscreamSocket.connect()
//    }
//    
//    func disconnect() {
//        starscreamSocket.disconnect()
//    }
//    
//    func write(string: String, completion: (() -> Void)?) {
//        starscreamSocket.write(string: string, completion: completion)
//    }
//}

struct SocketFactory: WebSocketFactory {
//    func create(with url: URL) -> WebSocketConnecting {
//        var request = URLRequest(url: url)
//        return WalletConnectSocket(request: request)
//    }
    func create(with url: URL) -> WebSocketConnecting {
        return WebSocket(url: url)
    }
}

extension WebSocket: WebSocketConnecting { }

struct DefaultCryptoProvider: CryptoProvider {
    
    public func recoverPubKey(signature: EthereumSignature, message: Data) throws -> Data {
        let publicKey = try EthereumPublicKey(
            message: message.bytes,
            v: EthereumQuantity(quantity: BigUInt(signature.v)),
            r: EthereumQuantity(signature.r),
            s: EthereumQuantity(signature.s)
        )
        return Data(publicKey.rawPublicKey)
    }
    
    public func keccak256(_ data: Data) -> Data {
        let digest = SHA3(variant: .keccak256)
        let hash = digest.calculate(for: [UInt8](data))
        return Data(hash)
    }
    
}

extension Blockchain {
    static var ethereum = Blockchain("eip155:1")!
    static var sepolia = Blockchain("eip155:11155111")!
}

class WalletConnect {
    
    @Published public var account: [Account] = []
    @Published public var rejectedReason: String = ""
    var publishers = [AnyCancellable]()
    private var sessions = [Session]()
    
    static var shared = WalletConnect()
    
    init() {
        let projectID = Bundle.main.infoDictionary?["WALLET_CONNECT_PROJECT_ID"] as? String ?? ""
        Networking.configure(projectId: projectID, socketFactory: SocketFactory()) 
        let metadata = AppMetadata(
            name: "Nos",
            description: "Connect your wallet to Nos to send payments to other users",
            url: "com.verse.Nos",
            icons: ["https://raw.githubusercontent.com/danlatorre/danlatorre.github.io/main/nos-account-logo.png"]
        )
        
        WalletConnectModal.configure(
            projectId: projectID,
            metadata: metadata
        )
        
        Sign.instance.sessionsPublisher
            .receive(on: DispatchQueue.main)
            .sink { sessions in
                self.sessions = sessions
            }
            .store(in: &publishers)
        
        Sign.instance.sessionSettlePublisher
            .receive(on: DispatchQueue.main)
            .sink { session in
                self.account = session.accounts
            }
            .store(in: &publishers)
        
        Sign.instance.sessionRejectionPublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { (session, reason) in
                self.rejectedReason = reason.message
            })
            .store(in: &publishers)
        
        WalletConnectModal.instance.sessionResponsePublisher
            .receive(on: DispatchQueue.main)
            .sink { response in
                print(response)
            }
            .store(in: &publishers)
        
        self.sessions = WalletConnectModal.instance.getSessions()
        _ = WalletConnectModal.instance.getPairings()
        
        let mainChain = [
            "eip155": ProposalNamespace(
                chains: [.ethereum], 
                methods: ["eth_sendTransaction", "personal_sign", "eth_signTypedData"], 
                events: []
            )
        ]
        
        let defaultSessionParams = SessionParams(
            requiredNamespaces: mainChain,
            optionalNamespaces: [:],
            sessionProperties: nil
        )
        
        WalletConnectModal.set(sessionParams: defaultSessionParams)
    }
    
    func connect() {
        Task { @MainActor in
            try! await WalletConnectModal.instance.cleanup()
            WalletConnectModal.present()
        }
    }
    
    func pay() async throws {
        guard let latestSession = sessions.last else {
            connect()
            return
        }
        
        let pairingTopic = latestSession.pairingTopic
        let topic = latestSession.topic
        let uri = try await WalletConnectModal.instance.connect(topic: pairingTopic)
        
        try await WalletConnectModal.instance.request(
            params: Request(
                topic: topic, 
                method: "eth_sendTransaction", 
                params: AnyCodable(
                    EthereumTransaction(
                        from: try EthereumAddress(hex: "0xF847D1Ae3DF7b18755cDD277acE94164DF9ac794", eip55: false),
                        to: try EthereumAddress(hex: "0x3d4E120592B3936b1da2Ac888221D4Eb364b5a64", eip55: false)
                    )
                ), 
                chainId: .ethereum
            )
        )
    }
}
