import Foundation
import SwiftUI
import CoreData
import Logger

/// The main state container for the Cashu wallet functionality.
/// This class manages the state of the wallet, including balances, mints, and transactions.
@Observable class WalletState {
    
    // MARK: - Properties
    
    /// The active wallet instance
    private(set) var activeWallet: WalletModel?
    
    /// Available mints
    private(set) var mints: [MintModel] = []
    
    /// Transaction history
    private(set) var transactions: [TransactionModel] = []
    
    /// Current wallet balance in sats
    private(set) var balance: Int = 0
    
    /// Wallet initialization state
    private(set) var walletInitialized: Bool = false
    
    /// Whether the wallet is currently being restored
    @ObservationIgnored private(set) var isRestoring: Bool = false
    
    /// Errors encountered during wallet operations
    @ObservationIgnored private(set) var lastError: Error?
    
    /// Wallet proofs (for Macadamia integration)
    @ObservationIgnored private var proofs: [ProofModel] = []
    
    // MARK: - Initialization
    
    init() {
        // Check if we have a wallet already
        loadExistingWallet()
    }
    
    // MARK: - Public Methods
    
    /// Creates a new wallet with a randomly generated seed
    func createNewWallet() async throws {
        Log.debug("Creating new wallet...")
        
        // Use MacadamiaWalletBridge to create the wallet with CashuSwift
        let bridge = MacadamiaWalletBridge(walletState: self)
        try await bridge.createWallet()
        
        // Wallet is now initialized through the MacadamiaWalletBridge
        // No need to call loadDefaultMints as the bridge handles this
        await calculateBalance()
    }
    
    /// Restores a wallet from a mnemonic phrase
    func restoreWallet(mnemonic: String) async throws {
        Log.debug("Restoring wallet from mnemonic...")
        
        await MainActor.run {
            self.isRestoring = true
        }
        
        defer {
            Task { @MainActor in
                self.isRestoring = false
            }
        }
        
        // Use MacadamiaWalletBridge to restore the wallet with CashuSwift
        let bridge = MacadamiaWalletBridge(walletState: self)
        try await bridge.restoreWallet(mnemonic: mnemonic)
        
        // Wallet is now initialized through the MacadamiaWalletBridge
        // No need to call loadDefaultMints as the bridge handles this
        await calculateBalance()
    }
    
    /// Adds a new mint to the wallet
    func addMint(url: URL) async throws {
        Log.debug("Adding mint: \(url.absoluteString)")
        
        // Use MacadamiaWalletBridge to add the mint with CashuSwift
        let bridge = MacadamiaWalletBridge(walletState: self)
        try await bridge.addMint(url: url)
        
        await calculateBalance()
    }
    
    /// Creates a new transaction to send tokens
    func send(amount: Int, to: String, mint: MintModel) async throws -> String {
        Log.debug("Sending \(amount) sats to \(to) using mint \(mint.url.absoluteString)")
        
        // Use MacadamiaWalletBridge to send tokens with CashuSwift
        let bridge = MacadamiaWalletBridge(walletState: self)
        return try await bridge.send(amount: amount, to: to, mint: mint)
    }
    
    /// Receives tokens from a token string
    func receive(token: String) async throws {
        Log.debug("Receiving token: \(token)")
        
        // Use MacadamiaWalletBridge to receive tokens with CashuSwift
        let bridge = MacadamiaWalletBridge(walletState: self)
        try await bridge.receive(token: token)
    }
    
    /// Creates a Lightning invoice and melts tokens to pay it
    func melt(invoice: String, mint: MintModel) async throws {
        Log.debug("Melting tokens for invoice: \(invoice)")
        
        // Use MacadamiaWalletBridge to melt tokens with CashuSwift
        let bridge = MacadamiaWalletBridge(walletState: self)
        try await bridge.melt(invoice: invoice, mint: mint)
    }
    
    /// Mints new tokens by paying a Lightning invoice
    func mint(amount: Int, mint: MintModel) async throws {
        Log.debug("Minting \(amount) sats using mint \(mint.url.absoluteString)")
        
        // Use MacadamiaWalletBridge to mint tokens with CashuSwift
        let bridge = MacadamiaWalletBridge(walletState: self)
        try await bridge.mint(amount: amount, mint: mint)
    }
    
    // MARK: - NIP-60/61 Methods
    
    /// Handles a wallet request event from Nostr
    func handleWalletRequest(request: [String: Any]) async throws -> [String: Any] {
        Log.debug("Handling wallet request: \(request)")
        
        // TODO: Implement NIP-60 wallet request handling
        
        // For now, return a placeholder response
        return ["status": "success", "message": "Not yet implemented"]
    }
    
    /// Handles a Cashu-specific request event from Nostr
    func handleCashuRequest(request: [String: Any]) async throws -> [String: Any] {
        Log.debug("Handling Cashu request: \(request)")
        
        // TODO: Implement NIP-61 Cashu request handling
        
        // For now, return a placeholder response
        return ["status": "success", "message": "Not yet implemented"]
    }
    
    // MARK: - Macadamia Integration Methods
    
    /// Add a new proof to the wallet
    func addProofs(_ newProofs: [ProofModel]) {
        self.proofs.append(contentsOf: newProofs)
        saveWalletState()
    }
    
    /// Mark proofs as spent
    func markProofsAsSpent(_ spentProofs: [ProofModel]) {
        for spentProof in spentProofs {
            if let index = proofs.firstIndex(where: { $0.id == spentProof.id }) {
                proofs[index].state = .spent
            }
        }
        saveWalletState()
    }
    
    /// Get valid proofs for a specific mint
    func getValidProofsForMint(_ mint: MintModel) -> [ProofModel] {
        return proofs.filter { $0.state == .valid && $0.mintURL == mint.url }
    }
    
    /// Get all valid proofs across all mints
    func getAllValidProofs() -> [ProofModel] {
        return proofs.filter { $0.state == .valid }
    }
    
    /// Add a transaction to the wallet
    func addTransaction(_ transaction: TransactionModel) {
        self.transactions.append(transaction)
        saveWalletState()
    }
    
    /// Get transaction index by ID
    func getTransactionIndex(id: UUID) -> Int? {
        return transactions.firstIndex(where: { $0.id == id })
    }
    
    /// Update transaction status
    func updateTransactionStatus(at index: Int, status: TransactionModel.TransactionStatus) {
        if index >= 0 && index < transactions.count {
            transactions[index].status = status
            saveWalletState()
        }
    }
    
    /// Get mint by URL
    func getMintByURL(_ url: URL) -> MintModel? {
        return mints.first(where: { $0.url == url })
    }
    
    /// Recalculate the wallet balance based on proofs and transactions
    func recalculateBalance() async {
        await calculateBalance()
        saveWalletState()
    }
    
    // MARK: - Private Methods
    
    /// Loads an existing wallet if available
    private func loadExistingWallet() {
        Log.debug("Checking for existing wallet...")
        
        // Load wallet data from UserDefaults for now (in production this should use Keychain)
        let defaults = UserDefaults.standard
        
        if let walletData = defaults.data(forKey: "nos_wallet_data"),
           let wallet = try? JSONDecoder().decode(WalletModel.self, from: walletData) {
            self.activeWallet = wallet
            self.walletInitialized = true
            
            // Load mints
            if let mintsData = defaults.data(forKey: "nos_wallet_mints"),
               let mints = try? JSONDecoder().decode([MintModel].self, from: mintsData) {
                self.mints = mints
            }
            
            // Load transactions
            if let transactionsData = defaults.data(forKey: "nos_wallet_transactions"),
               let transactions = try? JSONDecoder().decode([TransactionModel].self, from: transactionsData) {
                self.transactions = transactions
            }
            
            // Load proofs
            if let proofsData = defaults.data(forKey: "nos_wallet_proofs"),
               let proofs = try? JSONDecoder().decode([ProofModel].self, from: proofsData) {
                self.proofs = proofs
            }
            
            Log.info("Successfully loaded existing wallet with \(self.mints.count) mints and \(self.proofs.count) proofs")
        } else {
            walletInitialized = false
            Log.info("No existing wallet found")
        }
    }
    
    /// Saves the current wallet state
    private func saveWalletState() {
        // Save wallet data to UserDefaults for now (in production this should use Keychain)
        let defaults = UserDefaults.standard
        
        if let wallet = activeWallet,
           let walletData = try? JSONEncoder().encode(wallet) {
            defaults.set(walletData, forKey: "nos_wallet_data")
        }
        
        // Save mints
        if let mintsData = try? JSONEncoder().encode(mints) {
            defaults.set(mintsData, forKey: "nos_wallet_mints")
        }
        
        // Save transactions
        if let transactionsData = try? JSONEncoder().encode(transactions) {
            defaults.set(transactionsData, forKey: "nos_wallet_transactions")
        }
        
        // Save proofs
        if let proofsData = try? JSONEncoder().encode(proofs) {
            defaults.set(proofsData, forKey: "nos_wallet_proofs")
        }
        
        Log.debug("Wallet state saved")
    }
    
    /// Loads default mints
    private func loadDefaultMints() async throws {
        Log.debug("Loading default mints...")
        
        let defaultMintURLs = [
            URL(string: "https://legend.lnbits.com/cashu/api/v1/4gr9Xcmz3XEkUNwiBiQGoL")!,
            URL(string: "https://mint.bbqcashu.com")!
        ]
        
        for url in defaultMintURLs {
            try await addMint(url: url)
        }
    }
    
    /// Calculates the current wallet balance
    private func calculateBalance() async {
        Log.debug("Calculating wallet balance...")
        
        // First attempt to calculate from valid proofs
        let proofsBalance = proofs.filter { $0.state == .valid }.reduce(0) { $0 + $1.amount }
        
        // If we have proofs, use their sum as the balance
        if proofsBalance > 0 {
            await MainActor.run {
                self.balance = proofsBalance
            }
            return
        }
        
        // Fall back to calculating from transactions
        let calculatedBalance = transactions.reduce(0) { balance, transaction in
            switch transaction.type {
            case .mint, .receive:
                return balance + transaction.amount
            case .send, .melt:
                return balance - transaction.amount
            }
        }
        
        await MainActor.run {
            self.balance = max(0, calculatedBalance)
        }
    }
}