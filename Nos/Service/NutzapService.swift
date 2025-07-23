// ABOUTME: Service layer for handling NIP-61 nutzap operations
// ABOUTME: Manages sending, receiving, and validating P2PK-locked Cashu tokens via Nostr

import Foundation
import CoreData
import CashuSwift
import Logger

/// Service responsible for nutzap operations
public class NutzapService {
    
    private let context: NSManagedObjectContext
    private let walletService: CashuWalletService
    
    public init(context: NSManagedObjectContext, walletService: CashuWalletService) {
        self.context = context
        self.walletService = walletService
    }
    
    // MARK: - Sending Nutzaps
    
    /// Sends a nutzap to a recipient
    public func sendNutzap(
        amount: Int,
        to recipientPubkey: String,
        from wallet: CashuWallet,
        comment: String?,
        author: Author,
        referencedEvent: Event? = nil
    ) async throws -> Event {
        // Verify recipient has published nutzap info for this mint
        guard try await recipientCanReceiveNutzaps(recipientPubkey, at: wallet.mintURL) else {
            throw NutzapError.recipientNotSetUp
        }
        
        // Get recipient's P2PK pubkey
        let recipientP2PKPubkey = try await getRecipientP2PKPubkey(recipientPubkey, mint: wallet.mintURL)
        
        // Create nutzap event with P2PK-locked tokens
        let nutzap = try wallet.createNutzap(
            amount: amount,
            recipientPubkey: recipientP2PKPubkey,
            mint: wallet.mintURL,
            comment: comment,
            author: author
        )
        
        // Add referenced event tag if provided
        if let referencedEvent = referencedEvent {
            var tags = nutzap.allTags as? [[String]] ?? []
            tags.append(["e", referencedEvent.identifier ?? ""])
            nutzap.allTags = tags as NSObject
        }
        
        nutzap.createdAt = Date()
        try context.save()
        
        return nutzap
    }
    
    /// Checks if a recipient can receive nutzaps at a specific mint
    public func recipientCanReceiveNutzaps(_ recipientPubkey: String, at mintURL: String) async throws -> Bool {
        let request = NSFetchRequest<Event>(entityName: "Event")
        request.predicate = NSPredicate(
            format: "author.hexadecimalPublicKey == %@ AND kind == %d",
            recipientPubkey,
            EventKind.nutzapInfo.rawValue
        )
        request.fetchLimit = 1
        
        let nutzapInfoEvents = try context.fetch(request)
        
        for event in nutzapInfoEvents {
            guard let tags = event.allTags as? [[String]] else { continue }
            
            // Check if the mint is listed
            let mintTags = tags.filter { $0.count >= 2 && $0[0] == "mint" }
            if mintTags.contains(where: { $0[1] == mintURL }) {
                return true
            }
        }
        
        return false
    }
    
    // MARK: - Receiving Nutzaps
    
    /// Receives a nutzap and redeems the tokens into the wallet
    public func receiveNutzap(_ nutzapEvent: Event, into wallet: CashuWallet, author: Author) async throws -> Bool {
        // Verify the nutzap is for this recipient
        guard isNutzapForRecipient(nutzapEvent, recipientPubkey: author.hexadecimalPublicKey ?? "") else {
            throw NutzapError.notForThisRecipient
        }
        
        // Verify it hasn't been redeemed already
        guard !(try await isNutzapRedeemed(nutzapEvent)) else {
            throw NutzapError.alreadyRedeemed
        }
        
        // Extract and validate proofs from nutzap content
        guard let proofs = try? extractProofsFromNutzap(nutzapEvent) else {
            throw NutzapError.invalidProofs
        }
        
        // In production, would:
        // 1. Unlock the P2PK-locked tokens using wallet's private key
        // 2. Swap tokens at the mint
        // 3. Store the new unlocked tokens
        
        // For now, simulate by saving tokens
        try await walletService.saveTokens(proofs, for: wallet, mint: wallet.mintURL, author: author)
        
        // Create redemption event
        try await createRedemptionEvent(for: nutzapEvent, author: author)
        
        return true
    }
    
    /// Fetches all pending (unredeemed) nutzaps for a recipient
    public func fetchPendingNutzaps(for recipient: Author) async throws -> [Event] {
        // Fetch all nutzaps addressed to this recipient
        let nutzapRequest = NSFetchRequest<Event>(entityName: "Event")
        nutzapRequest.predicate = NSPredicate(format: "kind == %d", EventKind.nutzap.rawValue)
        
        let allNutzaps = try context.fetch(nutzapRequest)
        let recipientPubkey = recipient.hexadecimalPublicKey ?? ""
        
        // Filter for this recipient
        let recipientNutzaps = allNutzaps.filter { nutzap in
            isNutzapForRecipient(nutzap, recipientPubkey: recipientPubkey)
        }
        
        // Get redeemed nutzap IDs
        let redeemedIds = try await fetchRedeemedNutzapIds(for: recipient)
        
        // Return only unredeemed nutzaps
        return recipientNutzaps.filter { nutzap in
            !redeemedIds.contains(nutzap.identifier ?? "")
        }
    }
    
    // MARK: - Private Methods
    
    /// Gets the recipient's P2PK pubkey from their nutzap info event
    private func getRecipientP2PKPubkey(_ recipientPubkey: String, mint: String) async throws -> String {
        let request = NSFetchRequest<Event>(entityName: "Event")
        request.predicate = NSPredicate(
            format: "author.hexadecimalPublicKey == %@ AND kind == %d",
            recipientPubkey,
            EventKind.nutzapInfo.rawValue
        )
        request.fetchLimit = 1
        
        let events = try context.fetch(request)
        
        for event in events {
            guard let tags = event.allTags as? [[String]] else { continue }
            
            // Check if this mint is listed
            let mintTags = tags.filter { $0.count >= 2 && $0[0] == "mint" }
            guard mintTags.contains(where: { $0[1] == mint }) else { continue }
            
            // Get P2PK pubkey
            let pubkeyTags = tags.filter { $0.count >= 2 && $0[0] == "pubkey" }
            if let pubkeyTag = pubkeyTags.first {
                return pubkeyTag[1]
            }
        }
        
        throw NutzapError.recipientNotSetUp
    }
    
    /// Checks if a nutzap is for a specific recipient
    private func isNutzapForRecipient(_ nutzap: Event, recipientPubkey: String) -> Bool {
        guard let tags = nutzap.allTags as? [[String]] else { return false }
        return tags.contains { $0.count >= 2 && $0[0] == "p" && $0[1] == recipientPubkey }
    }
    
    /// Checks if a nutzap has been redeemed
    private func isNutzapRedeemed(_ nutzap: Event) async throws -> Bool {
        let request = NSFetchRequest<Event>(entityName: "Event")
        request.predicate = NSPredicate(format: "kind == %d", EventKind.cashuHistory.rawValue)
        
        let historyEvents = try context.fetch(request)
        
        for event in historyEvents {
            guard let tags = event.allTags as? [[String]] else { continue }
            
            // Check for redemption tag
            if tags.contains(where: { 
                $0.count >= 3 && $0[0] == "e" && $0[1] == nutzap.identifier && $0[2] == "redeemed" 
            }) {
                return true
            }
        }
        
        return false
    }
    
    /// Creates a redemption event marking a nutzap as redeemed
    private func createRedemptionEvent(for nutzap: Event, author: Author) async throws {
        let historyEvent = Event(context: context)
        historyEvent.kind = EventKind.cashuHistory.rawValue
        historyEvent.author = author
        historyEvent.createdAt = Date()
        
        // Add redemption tag
        historyEvent.allTags = [
            ["e", nutzap.identifier ?? "", "redeemed"],
            ["direction", "in"],
            ["amount", extractAmountFromNutzap(nutzap)]
        ] as NSObject
        
        try context.save()
    }
    
    /// Extracts proofs from nutzap content
    private func extractProofsFromNutzap(_ nutzap: Event) throws -> [CashuProof] {
        guard let content = nutzap.content,
              let data = content.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let proofsArray = json["proofs"] as? [[String: Any]] else {
            throw NutzapError.invalidProofs
        }
        
        return proofsArray.compactMap { dict in
            guard let amount = dict["amount"] as? Int,
                  let secret = dict["secret"] as? String,
                  let C = dict["C"] as? String else {
                return nil
            }
            
            return CashuProof(
                amount: amount,
                id: dict["id"] as? String ?? "",
                secret: secret,
                C: C
            )
        }
    }
    
    /// Extracts amount from nutzap tags
    private func extractAmountFromNutzap(_ nutzap: Event) -> String {
        guard let tags = nutzap.allTags as? [[String]] else { return "0" }
        
        for tag in tags {
            if tag.count >= 2 && tag[0] == "amount" {
                return tag[1]
            }
        }
        
        return "0"
    }
    
    /// Fetches IDs of redeemed nutzaps for a recipient
    private func fetchRedeemedNutzapIds(for recipient: Author) async throws -> Set<String> {
        let request = NSFetchRequest<Event>(entityName: "Event")
        request.predicate = NSPredicate(
            format: "author == %@ AND kind == %d",
            recipient,
            EventKind.cashuHistory.rawValue
        )
        
        let historyEvents = try context.fetch(request)
        var redeemedIds = Set<String>()
        
        for event in historyEvents {
            guard let tags = event.allTags as? [[String]] else { continue }
            
            for tag in tags {
                if tag.count >= 3 && tag[0] == "e" && tag[2] == "redeemed" {
                    redeemedIds.insert(tag[1])
                }
            }
        }
        
        return redeemedIds
    }
}

// MARK: - Errors

public enum NutzapError: LocalizedError {
    case recipientNotSetUp
    case notForThisRecipient
    case alreadyRedeemed
    case invalidProofs
    case insufficientBalance
    
    public var errorDescription: String? {
        switch self {
        case .recipientNotSetUp:
            return "Recipient has not set up nutzap receiving for this mint"
        case .notForThisRecipient:
            return "This nutzap is not addressed to you"
        case .alreadyRedeemed:
            return "This nutzap has already been redeemed"
        case .invalidProofs:
            return "Invalid or corrupted proofs in nutzap"
        case .insufficientBalance:
            return "Insufficient balance to send nutzap"
        }
    }
}