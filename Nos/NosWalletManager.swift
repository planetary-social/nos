import Foundation
import SwiftUI
import Logger

/// Main coordinator class for the wallet functionality in Nos.
/// This class brings together the wallet state, Nostr event handlers, and UI components.
@Observable class NosWalletManager {
    
    // MARK: - Properties
    
    /// The wallet state
    private(set) var walletState: Wallet.Models.WalletState
    
    /// The wallet connect handler for NIP-60
    private let walletConnectHandler: Wallet.NostrCashuBridge.NostrWalletConnectHandler
    
    /// The Cashu handler for NIP-61
    private let cashuHandler: Wallet.NostrCashuBridge.NostrCashuHandler
    
    /// Whether the wallet is currently initialized
    var isWalletInitialized: Bool {
        walletState.walletInitialized
    }
    
    /// Current wallet balance
    var balance: Int {
        walletState.balance
    }
    
    /// Available mints
    var mints: [Wallet.Models.MintModel] {
        walletState.mints
    }
    
    /// Transaction history
    var transactions: [Wallet.Models.TransactionModel] {
        walletState.transactions
    }
    
    // MARK: - Initialization
    
    init() {
        // Initialize the wallet state
        self.walletState = Wallet.Models.WalletState()
        
        // Initialize the wallet connect handler
        self.walletConnectHandler = Wallet.NostrCashuBridge.NostrWalletConnectHandler(walletState: walletState)
        
        // Initialize the Cashu handler
        self.cashuHandler = Wallet.NostrCashuBridge.NostrCashuHandler(
            walletState: walletState,
            walletConnectHandler: walletConnectHandler
        )
        
        // Set up Nostr event listeners
        setupEventListeners()
    }
    
    // MARK: - Wallet Setup Methods
    
    /// Creates a new wallet
    func createWallet() async throws {
        Log.info("Creating new wallet...")
        try await walletState.createNewWallet()
    }
    
    /// Restores a wallet from a mnemonic phrase
    func restoreWallet(mnemonic: String) async throws {
        Log.info("Restoring wallet from mnemonic...")
        try await walletState.restoreWallet(mnemonic: mnemonic)
    }
    
    // MARK: - Wallet Operations
    
    /// Adds a new mint to the wallet
    func addMint(url: URL) async throws {
        Log.info("Adding mint: \(url.absoluteString)")
        try await walletState.addMint(url: url)
    }
    
    /// Sends tokens to a receiver
    func sendTokens(amount: Int, to: String, mint: Wallet.Models.MintModel) async throws -> String {
        Log.info("Sending \(amount) sats to \(to)...")
        return try await walletState.send(amount: amount, to: to, mint: mint)
    }
    
    /// Receives tokens from a token string
    func receiveTokens(token: String) async throws {
        Log.info("Receiving token...")
        try await walletState.receive(token: token)
    }
    
    /// Mints new tokens
    func mintTokens(amount: Int, mint: Wallet.Models.MintModel) async throws {
        Log.info("Minting \(amount) sats...")
        try await walletState.mint(amount: amount, mint: mint)
    }
    
    /// Pays a Lightning invoice
    func payInvoice(invoice: String, mint: Wallet.Models.MintModel) async throws {
        Log.info("Paying Lightning invoice...")
        try await walletState.melt(invoice: invoice, mint: mint)
    }
    
    // MARK: - Nostr Event Handling
    
    /// Handles incoming Nostr events that might be wallet related
    func handleNostrEvent(event: [String: Any]) async throws -> [String: Any]? {
        Log.debug("Checking if event is wallet related: \(event)")
        
        guard let kind = event["kind"] as? Int else {
            return nil
        }
        
        guard let content = event["content"] as? String else {
            return nil
        }
        
        // Check if this is a wallet or Cashu event
        switch kind {
        case Wallet.NostrCashuBridge.WalletEventTypes.NIP60.walletRequestKind:
            Log.info("Received wallet_request event")
            if let requestData = Wallet.NostrCashuBridge.WalletEventTypes.parseWalletRequestEvent(eventContent: content) {
                let response = try await walletConnectHandler.handleWalletRequest(eventContent: requestData)
                let pubkey = event["pubkey"] as? String ?? ""
                return Wallet.NostrCashuBridge.WalletEventTypes.createWalletResponseEvent(
                    requestId: event["id"] as? String ?? "",
                    pubkey: pubkey,
                    response: response
                )
            }
            
        case Wallet.NostrCashuBridge.WalletEventTypes.NIP61.cashuRequestKind:
            Log.info("Received cashu_request event")
            if let requestData = Wallet.NostrCashuBridge.WalletEventTypes.parseCashuRequestEvent(eventContent: content) {
                let response = try await cashuHandler.handleCashuRequest(eventContent: requestData)
                let pubkey = event["pubkey"] as? String ?? ""
                return Wallet.NostrCashuBridge.WalletEventTypes.createCashuResponseEvent(
                    requestId: event["id"] as? String ?? "",
                    pubkey: pubkey,
                    response: response
                )
            }
            
        default:
            // Not a wallet-related event
            return nil
        }
        
        return nil
    }
    
    // MARK: - Private Methods
    
    /// Sets up listeners for Nostr events
    private func setupEventListeners() {
        Log.debug("Setting up Nostr event listeners for wallet events")
        
        // TODO: Implement listener setup with Nos event handling system
        // This will depend on how Nos handles Nostr events in general
    }
}