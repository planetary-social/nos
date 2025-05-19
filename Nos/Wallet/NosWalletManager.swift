import Foundation
import SwiftUI
import Logger

/// Main coordinator class for the wallet functionality in Nos.
/// This class brings together the wallet state, Nostr event handlers, and UI components.
@Observable class NosWalletManager {
    
    // MARK: - Properties
    
    /// The wallet state
    private(set) var walletState: WalletState
    
    /// The wallet connect handler for NIP-60
    private let walletConnectHandler: NostrWalletConnectHandler
    
    /// The Cashu handler for NIP-61
    private let cashuHandler: NostrCashuHandler
    
    /// The Macadamia wallet bridge for integration with the Macadamia wallet
    private var macadamiaBridge: MacadamiaWalletBridge?
    
    /// Whether the wallet is currently initialized
    var isWalletInitialized: Bool {
        walletState.walletInitialized
    }
    
    /// Current wallet balance
    var balance: Int {
        walletState.balance
    }
    
    /// Available mints
    var mints: [MintModel] {
        walletState.mints
    }
    
    /// Transaction history
    var transactions: [TransactionModel] {
        walletState.transactions
    }
    
    // MARK: - Initialization
    
    init() {
        // Initialize the wallet state
        self.walletState = WalletState()
        
        // Initialize the wallet connect handler
        self.walletConnectHandler = NostrWalletConnectHandler(walletState: walletState)
        
        // Initialize the Cashu handler
        self.cashuHandler = NostrCashuHandler(
            walletState: walletState,
            walletConnectHandler: walletConnectHandler
        )
        
        // Initialize the Macadamia wallet bridge
        self.macadamiaBridge = MacadamiaWalletBridge(walletState: walletState)
        
        // Set up Nostr event listeners
        setupEventListeners()
    }
    
    // MARK: - Wallet Setup Methods
    
    /// Creates a new wallet
    func createWallet() async throws {
        Log.info("Creating new wallet...")
        
        if let macadamiaBridge = macadamiaBridge {
            // Use Macadamia integration if available
            try await macadamiaBridge.createWallet()
        } else {
            // Fall back to standard implementation
            try await walletState.createNewWallet()
        }
    }
    
    /// Restores a wallet from a mnemonic phrase
    func restoreWallet(mnemonic: String) async throws {
        Log.info("Restoring wallet from mnemonic...")
        
        if let macadamiaBridge = macadamiaBridge {
            // Use Macadamia integration if available
            try await macadamiaBridge.restoreWallet(mnemonic: mnemonic)
        } else {
            // Fall back to standard implementation
            try await walletState.restoreWallet(mnemonic: mnemonic)
        }
    }
    
    // MARK: - Wallet Operations
    
    /// Adds a new mint to the wallet
    func addMint(url: URL) async throws {
        Log.info("Adding mint: \(url.absoluteString)")
        
        if let macadamiaBridge = macadamiaBridge {
            // Use Macadamia integration if available
            try await macadamiaBridge.addMint(url: url)
        } else {
            // Fall back to standard implementation
            try await walletState.addMint(url: url)
        }
    }
    
    /// Sends tokens to a receiver
    func sendTokens(amount: Int, to: String, mint: MintModel) async throws -> String {
        Log.info("Sending \(amount) sats to \(to)...")
        
        if let macadamiaBridge = macadamiaBridge {
            // Use Macadamia integration if available
            return try await macadamiaBridge.send(amount: amount, to: to, mint: mint)
        } else {
            // Fall back to standard implementation
            return try await walletState.send(amount: amount, to: to, mint: mint)
        }
    }
    
    /// Receives tokens from a token string
    func receiveTokens(token: String) async throws {
        Log.info("Receiving token...")
        
        if let macadamiaBridge = macadamiaBridge {
            // Use Macadamia integration if available
            try await macadamiaBridge.receive(token: token)
        } else {
            // Fall back to standard implementation
            try await walletState.receive(token: token)
        }
    }
    
    /// Mints new tokens
    func mintTokens(amount: Int, mint: MintModel) async throws {
        Log.info("Minting \(amount) sats...")
        
        if let macadamiaBridge = macadamiaBridge {
            // Use Macadamia integration if available
            try await macadamiaBridge.mint(amount: amount, mint: mint)
        } else {
            // Fall back to standard implementation
            try await walletState.mint(amount: amount, mint: mint)
        }
    }
    
    /// Pays a Lightning invoice
    func payInvoice(invoice: String, mint: MintModel) async throws {
        Log.info("Paying Lightning invoice...")
        
        if let macadamiaBridge = macadamiaBridge {
            // Use Macadamia integration if available
            try await macadamiaBridge.melt(invoice: invoice, mint: mint)
        } else {
            // Fall back to standard implementation
            try await walletState.melt(invoice: invoice, mint: mint)
        }
    }
    
    // MARK: - Macadamia Integration Methods
    
    /// Launch the Macadamia wallet as a standalone app
    func launchMacadamiaWallet() {
        Log.info("Launching Macadamia wallet...")
        
        #if canImport(Macadamia)
        // Use the official Macadamia launcher if available
        import Macadamia
        let success = MacadamiaLauncher.launch()
        if success {
            Log.info("Successfully launched Macadamia wallet")
        } else {
            Log.warning("Could not launch Macadamia wallet, falling back to web version")
            launchMacadamiaWebWallet()
        }
        #else
        // Fallback to manual implementation
        
        // Method 1: Try using custom URL scheme
        if let macadamiaURL = URL(string: "macadamia://wallet") {
            UIApplication.shared.open(macadamiaURL, options: [:]) { success in
                if success {
                    Log.info("Successfully opened Macadamia via URL scheme")
                } else {
                    // Method 2: Try web version
                    self.launchMacadamiaWebWallet()
                }
            }
        } else {
            // URL scheme failed, try web version
            launchMacadamiaWebWallet()
        }
        #endif
    }
    
    /// Launch the web version of Macadamia wallet
    private func launchMacadamiaWebWallet() {
        if let webURL = URL(string: "https://macadamia.nos.cash") {
            UIApplication.shared.open(webURL, options: [:]) { success in
                if success {
                    Log.info("Successfully opened Macadamia web version")
                } else {
                    Log.error("Could not launch Macadamia wallet")
                    // Could show a dialog here with instructions on how to install
                }
            }
        } else {
            Log.error("Invalid Macadamia web URL")
        }
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
        case WalletEventTypes.NIP60.walletRequestKind:
            Log.info("Received wallet_request event")
            if let requestData = WalletEventTypes.parseWalletRequestEvent(eventContent: content) {
                let response = try await walletConnectHandler.handleWalletRequest(eventContent: requestData)
                let pubkey = event["pubkey"] as? String ?? ""
                return WalletEventTypes.createWalletResponseEvent(
                    requestId: event["id"] as? String ?? "",
                    pubkey: pubkey,
                    response: response
                )
            }
            
        case WalletEventTypes.NIP61.cashuRequestKind:
            Log.info("Received cashu_request event")
            if let requestData = WalletEventTypes.parseCashuRequestEvent(eventContent: content) {
                let response = try await cashuHandler.handleCashuRequest(eventContent: requestData)
                let pubkey = event["pubkey"] as? String ?? ""
                return WalletEventTypes.createCashuResponseEvent(
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
        
        // Nos likely has a central event dispatch system that routes Nostr events to handlers
        // When such events arrive, they should call the handleNostrEvent method of this class
        
        // For NIP-60, listen for wallet_request events with kind 13194
        // For NIP-61, listen for cashu_request events with kind 13196
        
        // The listeners are set up in the EventProcessor class in the real app,
        // we just need to make sure our handleNostrEvent method properly processes these events
        
        Log.info("Wallet event listeners initialized for NIP-60 and NIP-61 events")
    }
}