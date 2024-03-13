import Logger
import Foundation
import WalletConnectPairing
import WalletConnectRelay
import WalletConnectSign
import Auth
import Combine

#if DEBUG
let walletConnectTestMode = true
let globalIDURLScheme = "globalid-staging://"
#else 
let walletConnectTestMode = false
let globalIDURLScheme = "globalid://"
#endif

/// Manages the state of a WalletConnect session that can be used to connect and communicate with a crypto wallet app.
class WalletConnectSessionManager {
    
    static var shared = WalletConnectSessionManager.initialize()
    
    let wcService: WalletConnectProvidable = USBCWalletConnectService()
    private var initiatedSession: Session?
    private var disposeBag = Set<AnyCancellable>()
    
    // Callbacks
    
    var onReinitiateConnection: (() -> Void)?
    var onSessionInitiated: ((Session) -> Void)?
    var onSessionResponse: ((Response) -> Void)?
    
    static func initialize() -> WalletConnectSessionManager {
        let manager = WalletConnectSessionManager()
        return manager
    }
    
    // Function creates pairing request
    // It returns wc:// deeplink, to use for pairing
    @MainActor func initiateConnectionRequest() async throws -> String {
        disposeBag = Set<AnyCancellable>()
        let uri = try await wcService.initialize()
        setupListeners()
        return uri
    }
    
    func saveInitiatedSessions(sessions: Session) {
        self.initiatedSession = sessions
    }
    
    func getAllSessions() -> [Session] {
        Sign.instance.getSessions()
    }
    
    func clearSessions() async throws {
        try await Sign.instance.cleanup()
        _ = try await initiateConnectionRequest()
    }
    
    func sendTransaction(
        fromAddress: String, 
        toAddress: String, 
        amount: String, 
        blockChain: WalletConnectChain
    ) async throws {
        guard let topic = initiatedSession?.topic else {
            throw SendUSBCError.noSession
        }
        
        guard let request = wcService.sendTransaction(
            topic: topic,
            fromAddress: fromAddress,
            toAddress: toAddress,
            amount: amount,
            blockChain: blockChain
        ) else { 
            throw SendUSBCError.couldNotCreateTransaction
        }
        
        try await Sign.instance.request(params: request)
    }
    
    // swiftlint:disable:next function_body_length
    func setupListeners() {
        Auth
            .instance
            .authResponsePublisher
            .sink { (_, result) in
                switch result {
                case .success(let cacao):
                    Logger.Log.info("Auth succedded \(cacao)")
                case .failure(let error):
                    Logger.Log.info("Auth failure \(error)")
                }
            }
            .store(in: &disposeBag)
        
        Networking.instance.socketConnectionStatusPublisher
            .sink { status in
                Logger.Log.info(String(describing: status))
            }
            .store(in: &disposeBag)
        
        Sign
            .instance
            .sessionProposalPublisher
            .receive(on: DispatchQueue.main)
            .sink { sessionProposal in
                // present proposal to the user
                Logger.Log.info(String(describing: sessionProposal))
            }
            .store(in: &disposeBag)
        Sign
            .instance
            .sessionEventPublisher
            .receive(on: DispatchQueue.main)
            .sink { (event, topic, _) in
                Logger.Log.info("Event \(event)  \n \n topic  \(topic)")
            }
            .store(in: &disposeBag)
        Sign
            .instance
            .sessionRequestPublisher
            .receive(on: DispatchQueue.main)
            .sink { sessionRequest in
                Logger.Log.info(String(describing: sessionRequest))
            }
            .store(in: &disposeBag)
        
        Sign
            .instance
            .sessionResponsePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sessionResponse in
                Logger.Log.info(String(describing: sessionResponse))
                self?.onSessionResponse?(sessionResponse)
            }
            .store(in: &disposeBag)
        
        Sign
            .instance
            .sessionSettlePublisher
            .receive(on: DispatchQueue.main)
            .sink { sessionRequest in
                // present session request to the user
                Logger.Log.info("Session settled! \n \n Users namespaces are \(sessionRequest.namespaces) \n \n")
                Logger.Log.info(String(describing: sessionRequest))
                self.initiatedSession = sessionRequest
                self.onSessionInitiated?(sessionRequest)
            }
            .store(in: &disposeBag)
        
        Sign
            .instance
            .sessionRejectionPublisher
            .receive(on: DispatchQueue.main)
            .sink { sessionRequest in
                // clear proposal which was rejected
                let proposal = sessionRequest.0
                let status = sessionRequest.1
                if status.code != 200 {
                    Logger.Log.info(
                        "Session cleaned: \(proposal.pairingTopic)\n dapp: \(proposal.proposer.name)\n status code " + 
                            "\(status.code)\n status mesasge \(status.message)"
                    )
                    Logger.Log.info("Recreating session")
                    Task {
                        self.onReinitiateConnection?()
                    }
                }
            }
            .store(in: &disposeBag)
        
        Auth
            .instance
            .socketConnectionStatusPublisher
            .receive(on: DispatchQueue.main)
            .sink { status in
                Logger.Log.info("Status connection  \(status)")
            }
            .store(in: &disposeBag)
    }
}
