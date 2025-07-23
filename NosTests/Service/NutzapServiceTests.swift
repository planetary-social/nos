// ABOUTME: Tests for NutzapService which handles sending and receiving nutzaps
// ABOUTME: Covers nutzap creation, validation, redemption, and P2PK operations

import XCTest
import CoreData
import Dependencies
@testable import Nos

final class NutzapServiceTests: CoreDataTestCase {
    
    var nutzapService: NutzapService!
    var walletService: CashuWalletService!
    
    @MainActor override func setUp() async throws {
        try await super.setUp()
        walletService = CashuWalletService(context: testContext)
        nutzapService = NutzapService(context: testContext, walletService: walletService)
    }
    
    func testSendNutzap() async throws {
        // Given
        let sender = try Author.findOrCreate(by: KeyFixture.pubKeyHex, context: testContext)
        let recipientPubkey = KeyFixture.pubKeyHex2
        let recipient = try Author.findOrCreate(by: recipientPubkey, context: testContext)
        
        // Create sender's wallet with some tokens
        let senderWallet = try await walletService.createWallet(
            name: "Sender Wallet",
            mintURL: "https://mint.minibits.cash/Bitcoin",
            for: sender
        )
        
        // Recipient must have published a nutzap info event
        let recipientWallet = CashuWallet(name: "Recipient", mintURL: senderWallet.mintURL)
        let nutzapInfo = try recipientWallet.createNutzapInfoEvent(
            author: recipient,
            relays: ["wss://relay.damus.io"],
            p2pkPubkey: recipientWallet.walletPublicKey
        )
        nutzapInfo.createdAt = Date()
        try testContext.save()
        
        // When
        let nutzap = try await nutzapService.sendNutzap(
            amount: 21,
            to: recipientPubkey,
            from: senderWallet,
            comment: "Great post!",
            author: sender
        )
        
        // Then
        XCTAssertNotNil(nutzap)
        XCTAssertEqual(nutzap.kind, EventKind.nutzap.rawValue)
        
        // Verify tags
        let tags = nutzap.allTags as? [[String]] ?? []
        XCTAssertTrue(tags.contains { $0.count >= 2 && $0[0] == "p" && $0[1] == recipientPubkey })
        XCTAssertTrue(tags.contains { $0.count >= 2 && $0[0] == "amount" && $0[1] == "21" })
        XCTAssertTrue(tags.contains { $0.count >= 2 && $0[0] == "comment" && $0[1] == "Great post!" })
    }
    
    func testCannotSendNutzapWithoutRecipientInfo() async throws {
        // Given
        let sender = try Author.findOrCreate(by: KeyFixture.pubKeyHex, context: testContext)
        let recipientPubkey = KeyFixture.pubKeyHex2
        // Note: No nutzap info event published by recipient
        
        let senderWallet = try await walletService.createWallet(
            name: "Sender Wallet",
            mintURL: "https://mint.minibits.cash/Bitcoin",
            for: sender
        )
        
        // When/Then
        do {
            _ = try await nutzapService.sendNutzap(
                amount: 21,
                to: recipientPubkey,
                from: senderWallet,
                comment: nil,
                author: sender
            )
            XCTFail("Should have thrown error")
        } catch NutzapError.recipientNotSetUp {
            // Expected error
        }
    }
    
    func testReceiveNutzap() async throws {
        // Given
        let sender = try Author.findOrCreate(by: KeyFixture.pubKeyHex, context: testContext)
        let recipient = try Author.findOrCreate(by: KeyFixture.pubKeyHex2, context: testContext)
        
        // Create recipient's wallet
        let recipientWallet = try await walletService.createWallet(
            name: "Recipient Wallet",
            mintURL: "https://mint.minibits.cash/Bitcoin",
            for: recipient
        )
        
        // Create a nutzap event
        let nutzapEvent = Event(context: testContext)
        nutzapEvent.kind = EventKind.nutzap.rawValue
        nutzapEvent.author = sender
        nutzapEvent.createdAt = Date()
        nutzapEvent.allTags = [
            ["p", recipient.hexadecimalPublicKey ?? ""],
            ["u", recipientWallet.mintURL],
            ["amount", "42"]
        ] as NSObject
        nutzapEvent.content = """
        {"proofs":[{"amount":42,"secret":"locked-secret","C":"locked-C","id":"proof-id"}]}
        """
        try testContext.save()
        
        // When
        let redeemed = try await nutzapService.receiveNutzap(
            nutzapEvent,
            into: recipientWallet,
            author: recipient
        )
        
        // Then
        XCTAssertTrue(redeemed)
        
        // Verify redemption event was created
        let historyEvents = Event.all(context: testContext).filter { 
            $0.kind == EventKind.cashuHistory.rawValue 
        }
        XCTAssertEqual(historyEvents.count, 1)
        
        // Verify it references the redeemed nutzap
        let tags = historyEvents.first?.allTags as? [[String]] ?? []
        XCTAssertTrue(tags.contains { $0.count >= 3 && $0[0] == "e" && $0[1] == nutzapEvent.identifier && $0[2] == "redeemed" })
    }
    
    func testValidateNutzapRecipient() async throws {
        // Given
        let recipient = try Author.findOrCreate(by: KeyFixture.pubKeyHex, context: testContext)
        let wallet = CashuWallet(name: "Test Wallet", mintURL: "https://mint.minibits.cash/Bitcoin")
        
        // Publish nutzap info
        let nutzapInfo = try wallet.createNutzapInfoEvent(
            author: recipient,
            relays: ["wss://relay.damus.io"],
            p2pkPubkey: wallet.walletPublicKey
        )
        nutzapInfo.createdAt = Date()
        try testContext.save()
        
        // When
        let canReceive = try await nutzapService.recipientCanReceiveNutzaps(
            recipient.hexadecimalPublicKey ?? "",
            at: wallet.mintURL
        )
        
        // Then
        XCTAssertTrue(canReceive)
    }
    
    func testFetchPendingNutzaps() async throws {
        // Given
        let sender = try Author.findOrCreate(by: KeyFixture.pubKeyHex, context: testContext)
        let recipient = try Author.findOrCreate(by: KeyFixture.pubKeyHex2, context: testContext)
        
        // Create multiple nutzap events
        for i in 1...3 {
            let nutzap = Event(context: testContext)
            nutzap.kind = EventKind.nutzap.rawValue
            nutzap.author = sender
            nutzap.createdAt = Date()
            nutzap.identifier = "nutzap-\(i)"
            nutzap.allTags = [
                ["p", recipient.hexadecimalPublicKey ?? ""],
                ["amount", String(i * 10)]
            ] as NSObject
        }
        
        // Mark one as redeemed
        let historyEvent = Event(context: testContext)
        historyEvent.kind = EventKind.cashuHistory.rawValue
        historyEvent.author = recipient
        historyEvent.createdAt = Date()
        historyEvent.allTags = [
            ["e", "nutzap-1", "redeemed"]
        ] as NSObject
        
        try testContext.save()
        
        // When
        let pendingNutzaps = try await nutzapService.fetchPendingNutzaps(for: recipient)
        
        // Then
        XCTAssertEqual(pendingNutzaps.count, 2) // Only 2 unredeemed
        XCTAssertTrue(pendingNutzaps.allSatisfy { $0.identifier != "nutzap-1" })
    }
}