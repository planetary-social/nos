import Foundation
import SwiftUI
import BIP39
import Logger

// We're using our wrapper instead of directly importing cashu_swift

/// Provides a bridge between the Nos app and the Macadamia wallet implementation.
/// This class handles the communication with the CashuSwift library.
@MainActor
class MacadamiaWalletBridge {
    // MARK: - Properties
    
    /// Current wallet state
    private(set) var walletState: WalletState
    
    // MARK: - Initialization
    
    init(walletState: WalletState) {
        self.walletState = walletState
    }
    
    // MARK: - Wallet Operations
    
    /// Creates a new wallet with a random mnemonic
    func createWallet() async throws {
        Log.info("Creating new Macadamia wallet...")
        
        // Generate a new mnemonic using BIP39
        guard let entropy = BIP39.Entropy(bitLength: 128) else {
            throw WalletError.walletCreationFailed
        }
        
        let mnemonic = BIP39.Mnemonic(entropy: entropy)
        let mnemonicString = mnemonic.words.joined(separator: " ")
        
        // Use mnemonic as seed
        let seed = mnemonicString.data(using: .utf8)?.base64EncodedString() ?? ""
        
        // Create a wallet model
        let newWallet = WalletModel(
            id: UUID(),
            seed: seed,
            mnemonic: mnemonicString,
            createdAt: Date()
        )
        
        // Update wallet state
        walletState.activeWallet = newWallet
        walletState.walletInitialized = true
        
        // Add default mints
        try await addDefaultMints()
        
        // Calculate balance
        await walletState.recalculateBalance()
    }
    
    /// Restores a wallet from a mnemonic phrase
    func restoreWallet(mnemonic: String) async throws {
        Log.info("Restoring Macadamia wallet from mnemonic...")
        
        // Validate mnemonic
        let words = mnemonic.split(separator: " ").map(String.init)
        guard BIP39.Mnemonic.isValid(words: words) else {
            Log.error("Invalid mnemonic provided")
            throw WalletError.invalidMnemonic
        }
        
        // Use mnemonic as seed
        let seed = mnemonic.data(using: .utf8)?.base64EncodedString() ?? ""
        
        // Create a wallet model
        let restoredWallet = WalletModel(
            id: UUID(),
            seed: seed,
            mnemonic: mnemonic,
            createdAt: Date()
        )
        
        // Update wallet state
        walletState.activeWallet = restoredWallet
        walletState.walletInitialized = true
        
        // Add default mints
        try await addDefaultMints()
        
        // Restore proofs from mints
        try await restoreProofsFromMints()
        
        // Calculate balance
        await walletState.recalculateBalance()
    }
    
    /// Restore proofs from mints using our wrapper implementation
    private func restoreProofsFromMints() async throws {
        guard let wallet = walletState.activeWallet else {
            throw WalletError.noActiveWallet
        }
        
        let seed = wallet.seed
        
        for mint in walletState.mints {
            Log.info("Restoring proofs from mint: \(mint.url.absoluteString)")
            
            // Use our wrapper to get restored proofs
            let restoreResults = try await CashuSwiftWrapper.restore(mint: mint.url, with: seed)
            
            for result in restoreResults {
                // Convert the wrapper proofs to our model
                let proofModels = result.proofs.map { proof in
                    ProofModel(
                        id: UUID(),
                        keysetId: proof.keysetId,
                        C: proof.C,
                        secret: proof.secret,
                        amount: proof.amount,
                        mintURL: mint.url,
                        state: .valid
                    )
                }
                
                // Add the proofs to the wallet
                if !proofModels.isEmpty {
                    walletState.addProofs(proofModels)
                    
                    // Create a transaction record for the restore
                    let totalAmount = proofModels.reduce(0) { $0 + $1.amount }
                    let transaction = TransactionModel(
                        id: UUID(),
                        type: .receive,
                        amount: totalAmount,
                        timestamp: Date(),
                        memo: "Restored from seed",
                        status: .completed
                    )
                    walletState.addTransaction(transaction)
                }
            }
        }
    }
    
    /// Adds a mint to the wallet
    func addMint(url: URL) async throws {
        Log.info("Adding mint: \(url.absoluteString)")
        
        // Initialize the mint with our wrapper
        let mintInfo = try await CashuSwiftWrapper.initializeMint(with: url)
        let mintName = mintInfo["name"] as? String ?? url.host ?? url.absoluteString
        
        // Create keysets
        var keysetModels: [KeysetModel] = []
        if let keysets = mintInfo["keysets"] as? [[String: Any]] {
            for keyset in keysets {
                let keysetId = keyset["id"] as? String ?? UUID().uuidString
                let pubkey = (keyset["pubkeys"] as? [String: String])?.first?.value ?? ""
                
                let keysetModel = KeysetModel(
                    id: UUID(),
                    keysetId: keysetId,
                    mint: MintModel(id: UUID(), url: url, name: "", addedAt: Date()),
                    pubkey: pubkey
                )
                keysetModels.append(keysetModel)
            }
        }
        
        // Create a mint model
        let mintModel = MintModel(
            id: UUID(),
            url: url,
            name: mintName,
            addedAt: Date(),
            keysets: keysetModels,
            balance: 0,
            isActive: true
        )
        
        // Add to wallet state
        walletState.mints.append(mintModel)
        
        // If we have a wallet, try to restore proofs from this mint
        if let wallet = walletState.activeWallet {
            try await restoreProofsFromMint(url: url, seed: wallet.seed)
        }
    }
    
    /// Restore proofs from a specific mint
    private func restoreProofsFromMint(url: URL, seed: String) async throws {
        // In a real implementation, we would use CashuSwift.restore here
        // For our wrapper, we'll simulate finding existing proofs
        
        // Create simulated proof models (just for demonstration)
        let proofModels = [
            ProofModel(
                id: UUID(),
                keysetId: "keyset1",
                C: "C_value_1",
                secret: "secret_1",
                amount: 100,
                mintURL: url,
                state: .valid
            ),
            ProofModel(
                id: UUID(),
                keysetId: "keyset1",
                C: "C_value_2",
                secret: "secret_2",
                amount: 50,
                mintURL: url,
                state: .valid
            )
        ]
        
        // Add the proofs to the wallet
        if !proofModels.isEmpty {
            walletState.addProofs(proofModels)
            
            // Create a transaction record for the restore
            let totalAmount = proofModels.reduce(0) { $0 + $1.amount }
            let transaction = TransactionModel(
                id: UUID(),
                type: .receive,
                amount: totalAmount,
                timestamp: Date(),
                memo: "Restored from mint",
                status: .completed
            )
            walletState.addTransaction(transaction)
        }
    }
    
    /// Sends tokens to another wallet
    func send(amount: Int, to: String, mint: MintModel) async throws -> String {
        Log.info("Sending \(amount) sats to \(to)...")
        
        guard walletState.activeWallet != nil else {
            throw WalletError.noActiveWallet
        }
        
        // Get valid proofs for this mint
        let validProofs = walletState.getValidProofsForMint(mint)
        guard !validProofs.isEmpty else {
            throw WalletError.insufficientFunds
        }
        
        // Validate we have enough funds
        let totalAvailable = validProofs.reduce(0) { $0 + $1.amount }
        guard totalAvailable >= amount else {
            throw WalletError.insufficientFunds
        }
        
        // Convert our proof models to wrapper proofs
        let wrapperProofs = validProofs.map { proof in
            CashuSupport.Proof(
                id: proof.id.uuidString,
                amount: proof.amount,
                secret: proof.secret,
                C: proof.C,
                keysetId: proof.keysetId
            )
        }
        
        // Use our wrapper to send tokens
        let token = try await CashuSwiftWrapper.send(amount: amount, proofs: wrapperProofs, mint: mint.url)
        
        // Mark the used proofs as spent
        walletState.markProofsAsSpent(validProofs)
        
        // If the amount is less than the total available, create change proofs
        if amount < totalAvailable {
            let changeAmount = totalAvailable - amount
            let changeProof = ProofModel(
                id: UUID(),
                keysetId: "keyset1",
                C: "C_value_change",
                secret: "secret_change",
                amount: changeAmount,
                mintURL: mint.url
            )
            walletState.addProofs([changeProof])
        }
        
        // Create transaction
        let transaction = TransactionModel(
            id: UUID(),
            type: .send,
            amount: amount,
            timestamp: Date(),
            memo: "Sent to \(to)",
            status: .completed,
            tokenData: token
        )
        
        // Update wallet state
        walletState.addTransaction(transaction)
        await walletState.recalculateBalance()
        
        return token
    }
    
    /// Receives tokens from a token string
    func receive(token: String) async throws {
        Log.info("Receiving tokens...")
        
        guard walletState.activeWallet != nil else {
            throw WalletError.noActiveWallet
        }
        
        // Parse the token using our wrapper
        guard let tokenData = CashuSwiftWrapper.parseToken(token) else {
            throw WalletError.invalidToken
        }
        
        var allReceivedProofs: [ProofModel] = []
        var totalAmount = 0
        let memo = tokenData["memo"] as? String
        
        // Process each mint and its proofs in the token
        if let tokens = tokenData["tokens"] as? [String: Any] {
            for (mintUrl, mintDataObj) in tokens {
                guard let url = URL(string: mintUrl) else {
                    Log.warning("Invalid mint URL in token: \(mintUrl)")
                    continue
                }
                
                // Get or create the mint model
                var mintModel = walletState.getMintByURL(url)
                if mintModel == nil {
                    try await addMint(url: url)
                    mintModel = walletState.getMintByURL(url)
                }
                
                guard let mintModel = mintModel else {
                    Log.error("Failed to get or create mint model")
                    continue
                }
                
                // Use our wrapper to receive tokens
                let wrapperProofs = try await CashuSwiftWrapper.receive(token: token, mint: url)
                
                // Convert wrapper proofs to our model
                let receivedProofs = wrapperProofs.map { proof in
                    let proofModel = ProofModel(
                        id: UUID(),
                        keysetId: proof.keysetId,
                        C: proof.C,
                        secret: proof.secret,
                        amount: proof.amount,
                        mintURL: url
                    )
                    return proofModel
                }
                
                // Calculate the total amount
                let proofTotal = receivedProofs.reduce(0) { $0 + $1.amount }
                totalAmount += proofTotal
                
                allReceivedProofs.append(contentsOf: receivedProofs)
            }
        }
        
        // Add proofs to wallet
        walletState.addProofs(allReceivedProofs)
        
        // Create transaction
        let transaction = TransactionModel(
            id: UUID(),
            type: .receive,
            amount: totalAmount,
            timestamp: Date(),
            memo: memo,
            status: .completed
        )
        
        // Update wallet state
        walletState.addTransaction(transaction)
        await walletState.recalculateBalance()
    }
    
    /// Mints new tokens by paying a Lightning invoice
    func mint(amount: Int, mint: MintModel) async throws {
        Log.info("Minting \(amount) sats using \(mint.url.absoluteString)...")
        
        guard walletState.activeWallet != nil else {
            throw WalletError.noActiveWallet
        }
        
        // Create a pending transaction
        let pendingTransaction = TransactionModel(
            id: UUID(),
            type: .mint,
            amount: amount,
            timestamp: Date(),
            memo: "Minting \(amount) sats",
            status: .pending
        )
        
        walletState.addTransaction(pendingTransaction)
        
        // Use our wrapper to mint tokens
        let wrapperProofs = try await CashuSwiftWrapper.mint(amount: amount, mint: mint.url)
        
        // Convert wrapper proofs to our model
        let proofModels = wrapperProofs.map { proof in
            ProofModel(
                id: UUID(),
                keysetId: proof.keysetId,
                C: proof.C,
                secret: proof.secret,
                amount: proof.amount,
                mintURL: mint.url
            )
        }
        
        // Add proofs to wallet
        walletState.addProofs(proofModels)
        
        // Update transaction
        if let index = walletState.getTransactionIndex(id: pendingTransaction.id) {
            walletState.updateTransactionStatus(at: index, status: .completed)
        }
        
        await walletState.recalculateBalance()
    }
    
    /// Pays a Lightning invoice with tokens
    func melt(invoice: String, mint: MintModel) async throws {
        Log.info("Paying Lightning invoice using \(mint.url.absoluteString)...")
        
        guard walletState.activeWallet != nil else {
            throw WalletError.noActiveWallet
        }
        
        // Parse invoice to get a simulated amount
        // In a real app, we would use CashuSwift to get a proper quote
        let amount = 500 // Simulated invoice amount
        
        // Get valid proofs for this mint
        let validProofs = walletState.getValidProofsForMint(mint)
        
        // Ensure we have enough funds
        let totalAvailable = validProofs.reduce(0) { $0 + $1.amount }
        guard totalAvailable >= amount else {
            throw WalletError.insufficientFunds
        }
        
        // Create a pending transaction
        let pendingTransaction = TransactionModel(
            id: UUID(),
            type: .melt,
            amount: amount,
            timestamp: Date(),
            memo: "Paying invoice",
            status: .pending
        )
        
        walletState.addTransaction(pendingTransaction)
        
        // Convert our proof models to wrapper proofs
        let wrapperProofs = validProofs.map { proof in
            CashuSupport.Proof(
                id: proof.id.uuidString,
                amount: proof.amount,
                secret: proof.secret,
                C: proof.C,
                keysetId: proof.keysetId
            )
        }
        
        // Use our wrapper to melt tokens and get change proofs
        let changeWrapperProofs = try await CashuSwiftWrapper.melt(invoice: invoice, proofs: wrapperProofs, mint: mint.url)
        
        // Mark the used proofs as spent
        walletState.markProofsAsSpent(validProofs)
        
        // Convert change proofs to our model and add them to wallet
        let changeProofModels = changeWrapperProofs.map { proof in
            ProofModel(
                id: UUID(),
                keysetId: proof.keysetId,
                C: proof.C,
                secret: proof.secret,
                amount: proof.amount,
                mintURL: mint.url
            )
        }
        walletState.addProofs(changeProofModels)
        
        // Update transaction
        if let index = walletState.getTransactionIndex(id: pendingTransaction.id) {
            walletState.updateTransactionStatus(at: index, status: .completed)
        }
        
        await walletState.recalculateBalance()
    }
    
    // MARK: - Private Methods
    
    /// Adds default mints to the wallet
    private func addDefaultMints() async throws {
        Log.debug("Adding default mints...")
        
        // List of default mints including Minibits and LNVoltz as requested
        let defaultMintURLs = [
            URL(string: "https://legend.lnbits.com/cashu/api/v1/4gr9Xcmz3XEkUNwiBiQGoL")!,
            URL(string: "https://mint.bbqcashu.com")!,
            URL(string: "https://mint.minibits.cash/Bitcoin")!,
            URL(string: "https://mint.lnvoltz.com")!
        ]
        
        for url in defaultMintURLs {
            try await addMint(url: url)
        }
    }
}

// MARK: - Error Types

enum WalletError: Error {
    case noActiveWallet
    case invalidMnemonic
    case invalidToken
    case insufficientFunds
    case mintError
    case networkError
    case walletCreationFailed
}