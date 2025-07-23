// ABOUTME: Integration tests for full Cashu wallet and nutzap flow
// ABOUTME: Tests end-to-end scenarios including wallet creation, token management, and nutzaps

import XCTest
import CoreData
import Dependencies
@testable import Nos

final class CashuIntegrationTests: CoreDataTestCase {
    
    var walletService: CashuWalletService!
    var nutzapService: NutzapService!
    
    @MainActor override func setUp() async throws {
        try await super.setUp()
        walletService = CashuWalletService(context: testContext)
        nutzapService = NutzapService(context: testContext, walletService: walletService)
    }
    
    func testFullNutzapFlow() async throws {
        // MARK: - Setup Users
        let alice = try Author.findOrCreate(by: KeyFixture.alice.publicKeyHex, context: testContext)
        let bob = try Author.findOrCreate(by: KeyFixture.bob.publicKeyHex, context: testContext)
        
        // MARK: - Create Wallets
        
        // Alice creates a wallet
        let aliceWallet = try await walletService.createWallet(
            name: "Alice's Wallet",
            mintURL: "https://mint.minibits.cash/Bitcoin",
            for: alice
        )
        
        // Bob creates a wallet on the same mint
        let bobWallet = try await walletService.createWallet(
            name: "Bob's Wallet",
            mintURL: "https://mint.minibits.cash/Bitcoin",
            for: bob
        )
        
        // MARK: - Setup Nutzap Receiving
        
        // Bob publishes his nutzap info to receive nutzaps
        let bobNutzapInfo = try bobWallet.createNutzapInfoEvent(
            author: bob,
            relays: ["wss://relay.damus.io", "wss://relay.nostr.band"],
            p2pkPubkey: bobWallet.walletPublicKey
        )
        bobNutzapInfo.createdAt = Date()
        try testContext.save()
        
        // MARK: - Alice Funds Her Wallet
        
        // Simulate Alice receiving some tokens (in real app, would mint from Lightning)
        let aliceTokens = [
            CashuProof(amount: 1, id: "mint-id", secret: "secret1", C: "C1"),
            CashuProof(amount: 4, id: "mint-id", secret: "secret2", C: "C2"),
            CashuProof(amount: 16, id: "mint-id", secret: "secret3", C: "C3"),
            CashuProof(amount: 64, id: "mint-id", secret: "secret4", C: "C4")
        ]
        
        try await walletService.saveTokens(
            aliceTokens,
            for: aliceWallet,
            mint: aliceWallet.mintURL,
            author: alice
        )
        
        // Verify Alice's balance
        let aliceBalance = try await walletService.getBalance(for: aliceWallet, author: alice)
        XCTAssertEqual(aliceBalance, 85) // 1 + 4 + 16 + 64
        
        // MARK: - Send Nutzap
        
        // Alice sends 21 sats to Bob via nutzap
        let nutzapEvent = try await nutzapService.sendNutzap(
            amount: 21,
            to: bob.hexadecimalPublicKey ?? "",
            from: aliceWallet,
            comment: "Thanks for the great post!",
            author: alice
        )
        
        XCTAssertNotNil(nutzapEvent)
        XCTAssertEqual(nutzapEvent.kind, EventKind.nutzap.rawValue)
        
        // MARK: - Bob Receives Nutzap
        
        // Bob checks for pending nutzaps
        let pendingNutzaps = try await nutzapService.fetchPendingNutzaps(for: bob)
        XCTAssertEqual(pendingNutzaps.count, 1)
        XCTAssertEqual(pendingNutzaps.first?.identifier, nutzapEvent.identifier)
        
        // Bob redeems the nutzap
        let redeemed = try await nutzapService.receiveNutzap(
            nutzapEvent,
            into: bobWallet,
            author: bob
        )
        XCTAssertTrue(redeemed)
        
        // Verify Bob's balance increased
        let bobBalance = try await walletService.getBalance(for: bobWallet, author: bob)
        XCTAssertEqual(bobBalance, 21)
        
        // Verify nutzap is no longer pending
        let pendingAfterRedeem = try await nutzapService.fetchPendingNutzaps(for: bob)
        XCTAssertEqual(pendingAfterRedeem.count, 0)
        
        // MARK: - Verify Event Trail
        
        // Check wallet events
        let aliceWalletEvents = try await walletService.fetchWalletEvents(for: alice)
        XCTAssertEqual(aliceWalletEvents.count, 1)
        
        let bobWalletEvents = try await walletService.fetchWalletEvents(for: bob)
        XCTAssertEqual(bobWalletEvents.count, 1)
        
        // Check token events
        let aliceTokenEvents = try await walletService.fetchTokenEvents(
            for: alice,
            mint: aliceWallet.mintURL
        )
        XCTAssertEqual(aliceTokenEvents.count, 1) // Initial funding
        
        let bobTokenEvents = try await walletService.fetchTokenEvents(
            for: bob,
            mint: bobWallet.mintURL
        )
        XCTAssertEqual(bobTokenEvents.count, 1) // From redeemed nutzap
        
        // Check history events
        let historyEvents = Event.all(context: testContext).filter {
            $0.kind == EventKind.cashuHistory.rawValue
        }
        XCTAssertEqual(historyEvents.count, 1) // Bob's redemption
        
        // Verify redemption event tags
        if let redemptionEvent = historyEvents.first {
            let tags = redemptionEvent.allTags as? [[String]] ?? []
            XCTAssertTrue(tags.contains { $0.count >= 3 && $0[0] == "e" && $0[1] == nutzapEvent.identifier && $0[2] == "redeemed" })
            XCTAssertTrue(tags.contains { $0.count >= 2 && $0[0] == "direction" && $0[1] == "in" })
            XCTAssertTrue(tags.contains { $0.count >= 2 && $0[0] == "amount" && $0[1] == "21" })
        }
    }
    
    func testMultipleMintSupport() async throws {
        // Test that wallets can support multiple mints
        let user = try Author.findOrCreate(by: KeyFixture.pubKeyHex, context: testContext)
        
        // Create wallet with primary mint
        let wallet = try await walletService.createWallet(
            name: "Multi-Mint Wallet",
            mintURL: "https://mint.minibits.cash/Bitcoin",
            for: user
        )
        
        // Add additional mints
        wallet.addMint("https://legend.lnbits.com/cashu/api/v1/4gr9Xcmz3XEkUNwiBiQGoC")
        wallet.addMint("https://8333.space:3338")
        
        // Update wallet event with new mints
        let updatedWalletEvent = try wallet.createWalletEvent(author: user)
        updatedWalletEvent.createdAt = Date()
        try testContext.save()
        
        // Verify all mints are included
        let tags = updatedWalletEvent.allTags as? [[String]] ?? []
        let mintTags = tags.filter { $0.first == "mint" }
        XCTAssertEqual(mintTags.count, 3)
        
        // Publish nutzap info with multiple mints
        let nutzapInfo = try wallet.createNutzapInfoEvent(
            author: user,
            relays: ["wss://relay.damus.io"],
            p2pkPubkey: wallet.walletPublicKey
        )
        
        let nutzapTags = nutzapInfo.allTags as? [[String]] ?? []
        let nutzapMintTags = nutzapTags.filter { $0.first == "mint" }
        XCTAssertEqual(nutzapMintTags.count, 3)
    }
    
    func testNutzapToEventReference() async throws {
        // Test sending a nutzap that references a specific event (like zapping a note)
        let alice = try Author.findOrCreate(by: KeyFixture.alice.publicKeyHex, context: testContext)
        let bob = try Author.findOrCreate(by: KeyFixture.bob.publicKeyHex, context: testContext)
        
        // Create Bob's note
        let bobsNote = Event(context: testContext)
        bobsNote.kind = EventKind.text.rawValue
        bobsNote.author = bob
        bobsNote.content = "Hello, Nostr!"
        bobsNote.identifier = "note123"
        bobsNote.createdAt = Date()
        try testContext.save()
        
        // Setup wallets and nutzap info
        let aliceWallet = try await walletService.createWallet(
            name: "Alice's Wallet",
            mintURL: "https://mint.minibits.cash/Bitcoin",
            for: alice
        )
        
        let bobWallet = CashuWallet(name: "Bob's Wallet", mintURL: aliceWallet.mintURL)
        let bobNutzapInfo = try bobWallet.createNutzapInfoEvent(
            author: bob,
            relays: ["wss://relay.damus.io"],
            p2pkPubkey: bobWallet.walletPublicKey
        )
        try testContext.save()
        
        // Alice sends nutzap referencing Bob's note
        let nutzap = try await nutzapService.sendNutzap(
            amount: 100,
            to: bob.hexadecimalPublicKey ?? "",
            from: aliceWallet,
            comment: "Great post!",
            author: alice,
            referencedEvent: bobsNote
        )
        
        // Verify event reference tag
        let tags = nutzap.allTags as? [[String]] ?? []
        XCTAssertTrue(tags.contains { $0.count >= 2 && $0[0] == "e" && $0[1] == bobsNote.identifier })
    }
}