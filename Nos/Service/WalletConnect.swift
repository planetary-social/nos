//
//  WalletConnect.swift
//  Nos
//
//  Created by Matthew Lorentz on 9/19/23.
//

import Foundation
import Logger
import Starscream
import Auth
import WalletConnectModal
import WalletConnectRelay
import WalletConnectNetworking
import Web3Wallet
import CryptoSwift
import Web3
import Combine

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


class WalletConnect {
    
    @Published public var account: [Account] = []
    @Published public var rejectedReason: String = ""
    var publishers = [AnyCancellable]()
    
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
        
        let methods: Set<String> = ["personal_sign"]
        let mainChain = [
            "eip155": ProposalNamespace(chains: [Blockchain("eip155:11155111")!], methods: [], events: [])
        ]
//        let methods: Set<String> = ["eth_sendTransaction", "personal_sign", "eth_signTypedData"]
        let events: Set<String> = ["chainChanged", "accountsChanged"]
        let blockchains: Set<Blockchain> = [Blockchain("eip155:11155111")!]
        let namespaces: [String: ProposalNamespace] = [
            "eip155": ProposalNamespace(
                chains: blockchains,
                methods: methods,
                events: []
            )
        ]
        let sessionProperties: [String: String] = [
            "caip154-mandatory": "true"
        ]
        
        let defaultSessionParams = SessionParams(
            requiredNamespaces: mainChain,
            optionalNamespaces: [:],
            sessionProperties: nil
        )
        
        WalletConnectModal.set(sessionParams: defaultSessionParams)
    }
    
    func connect() {
        Task {
            let _ = try! await WalletConnectModal.instance.connect(topic: nil)
            WalletConnectModal.present()
        }
    }
}
