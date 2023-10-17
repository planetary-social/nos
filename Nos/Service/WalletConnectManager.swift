//
//  WalletConnectManager.swift
//  DAppExample
//
//  Created by Marcel Salej on 27/09/2023.
//

import Foundation
import WalletConnectPairing
import WalletConnectRelay
import WalletConnectSign
import Auth
import Combine

class WalletConnectManager {
    
    static var shared: WalletConnectManager = WalletConnectManager.initialize()
    var testMode: Bool = true
    let wcService: WalletConnectProvidable = ETHWalletConnectService()
    private var initiatedSession: Session?
    private var disposeBag = Set<AnyCancellable>()
    
    // Callbacks
    
    var onReinitiateConnection: (() -> Void)?
    var onSessionInitiated: ((Session) -> Void)?
    var onSessionResponse: ((Response) -> Void)?
    
    
    static func initialize() -> WalletConnectManager {
        let manager = WalletConnectManager()
        return manager
    }
    
    // Function creates pairing request
    // It returns wc:// deeplink, to use for pairing
    func initiateConnectionRequest() async throws -> String {
        let uri = try await wcService.initialize()
        setupListeners()
        return uri
    }
    
    func saveInitiatedSessions(sessions: Session) {
        self.initiatedSession = sessions
    }
    
    func getAllSessions() -> [Session] {
        return Sign.instance.getSessions()
    }
    
    func deleteSession(topic: String) async throws {
        return try await Sign.instance.disconnect(topic: topic)
    }
    
    
    func personalSign(message: String, address: String, blockChain: SupportedChainType) {
        if let topic = initiatedSession?.topic {
            Task {
                do {
                    let signRequest = wcService.personalSign(topic: topic, message: message, address: address, blockChain: blockChain)
                    try await Sign.instance.request(params: signRequest)
                } catch {
                    print("\n errorr \n personalSign  \(error)")
                }
            }
        }
    }
    
    func getBalance(address: String, blockChain: SupportedChainType) {
        if let topic = initiatedSession?.topic {
            Task {
                do {
                    let balanceRequest = wcService.getBalance(topic: topic,
                                                              address: address,
                                                              blockChain: blockChain)
                    try await Sign.instance.request(params: balanceRequest)
                } catch {
                    print("\n errorr \n get balance  \(error)")
                }
            }
        }
    }
    
    func sendTransaction(fromAddress: String, toAddress: String, amount: String, blockChain: SupportedChainType) {
        if let topic = initiatedSession?.topic {
            Task {
                do {
                    guard let request = wcService.sendTransaction(topic: topic,
                                                                  fromAddress: fromAddress,
                                                                  toAddress: toAddress,
                                                                  amount: amount,
                                                                  blockChain: blockChain) else { return }
                    try await Sign.instance.request(params: request)
                } catch {
                    print("\n errorr \n get balance  \(error)")
                }
            }
        }
    }
}

private extension WalletConnectManager {
    func setupListeners() {
        Auth
            .instance
            .authResponsePublisher
            .sink { [weak self] (_, result) in
                switch result {
                case .success(let cacao):
                    print("Auth succedded \(cacao)")
                case .failure(let error):
                    print("Auth failure \(error)")
                }
            }.store(in: &disposeBag)
        
        Networking.instance.socketConnectionStatusPublisher.sink { status in
            print(status)
        }.store(in: &disposeBag)
        
        Sign
            .instance
            .sessionProposalPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sessionProposal in
                // present proposal to the user
                print(sessionProposal)
                
            }.store(in: &disposeBag)
        Sign
            .instance
            .sessionEventPublisher
            .receive(on: DispatchQueue.main)
            .sink { (event, topic, _) in
                print("Ecvent \(event)  \n \n topic  \(topic)")
            }.store(in: &disposeBag)
        Sign
            .instance
            .sessionRequestPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sessionRequest in
                // present session request to the user
                print(sessionRequest)
                
                
            }.store(in: &disposeBag)
        
        Sign
            .instance
            .sessionResponsePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sessionResponse in
                // present session request to the user
                print(sessionResponse)
                self?.onSessionResponse?(sessionResponse)
            }.store(in: &disposeBag)
        
        Sign
            .instance
            .sessionSettlePublisher
            .receive(on: DispatchQueue.main)
            .sink { sessionRequest in
                // present session request to the user
                print("Session settled! \n \n Users namespaces are \(sessionRequest.namespaces) \n \n")
                print(sessionRequest)
                self.initiatedSession = sessionRequest
                self.onSessionInitiated?(sessionRequest)
                
            }.store(in: &disposeBag)
        
        Sign
            .instance
            .sessionRejectionPublisher
            .receive(on: DispatchQueue.main)
            .sink { sessionRequest in
                // clear proposal which was rejected
                let proposal = sessionRequest.0
                let status = sessionRequest.1
                if status.code != 200 {
                    print("Session cleaned:   \(proposal.pairingTopic)  \n  dapp: \(proposal.proposer.name) \n status code \(status.code) \n status mesasge \(status.message)")
                    print("Recreating session")
                    Task {
                        self.onReinitiateConnection?()
                    }
                }
            }.store(in: &disposeBag)
        
        Auth
            .instance
            .socketConnectionStatusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                print("Status connection  \(status)")
            }
        
    }
}
