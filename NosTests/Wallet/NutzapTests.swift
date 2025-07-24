// ABOUTME: Tests for NIP-61 nutzap creation and validation
// ABOUTME: Covers P2PK token locking and nutzap event structure

import XCTest
import CoreData
@testable import Nos

final class NutzapTests: CoreDataTestCase {
    
    func testCreateNutzapInfoEvent() throws {
        // Given
        let wallet = CashuWallet(name: "Test Wallet", mintURL: "https://mint.minibits.cash/Bitcoin")
        let author = try Author.findOrCreate(by: KeyFixture.pubKeyHex, context: testContext)
        let relays = ["wss://relay.damus.io", "wss://nos.social"]
        
        // When
        let nutzapInfo = try wallet.createNutzapInfoEvent(
            author: author,
            relays: relays,
            p2pkPubkey: wallet.walletPublicKey
        )
        
        // Then
        XCTAssertEqual(nutzapInfo.kind, EventKind.nutzapInfo.rawValue)
        XCTAssertEqual(nutzapInfo.author, author)
        
        // Verify mint tags
        let mintTags = nutzapInfo.allTags.filter { $0.name == "mint" }
        XCTAssertEqual(mintTags.count, 1)
        XCTAssertEqual(mintTags.first?.value, wallet.mintURL)
        
        // Verify relay tags
        let relayTags = nutzapInfo.allTags.filter { $0.name == "relay" }
        XCTAssertEqual(relayTags.count, 2)
        
        // Verify pubkey tag
        let pubkeyTags = nutzapInfo.allTags.filter { $0.name == "pubkey" }
        XCTAssertEqual(pubkeyTags.count, 1)
        XCTAssertEqual(pubkeyTags.first?.value, "02" + wallet.walletPublicKey) // P2PK prefix
    }
    
    func testCreateNutzapEvent() async throws {
        // Given
        let senderWallet = CashuWallet(name: "Sender", mintURL: "https://mint.minibits.cash/Bitcoin")
        let recipientPubkey = "02" + KeyFixture.pubKeyHex // P2PK format
        let amount = 21
        let comment = "Great post!"
        let author = try Author.findOrCreate(by: KeyFixture.pubKeyHex, context: testContext)
        
        // When
        let nutzap = try await senderWallet.createNutzap(
            amount: amount,
            recipientPubkey: recipientPubkey,
            mint: senderWallet.mintURL,
            comment: comment,
            author: author
        )
        
        // Then
        XCTAssertEqual(nutzap.kind, EventKind.nutzap.rawValue)
        XCTAssertEqual(nutzap.author, author)
        
        // Verify recipient tag
        let recipientTags = nutzap.allTags.filter { $0.name == "p" }
        XCTAssertEqual(recipientTags.count, 1)
        XCTAssertEqual(recipientTags.first?.value, recipientPubkey.dropFirst(2)) // Without P2PK prefix
        
        // Verify mint tag
        let mintTags = nutzap.allTags.filter { $0.name == "u" }
        XCTAssertEqual(mintTags.count, 1)
        XCTAssertEqual(mintTags.first?.value, senderWallet.mintURL)
        
        // Verify amount tag
        let amountTags = nutzap.allTags.filter { $0.name == "amount" }
        XCTAssertEqual(amountTags.count, 1)
        XCTAssertEqual(amountTags.first?.value, String(amount))
        
        // Verify comment tag
        let commentTags = nutzap.allTags.filter { $0.name == "comment" }
        XCTAssertEqual(commentTags.count, 1)
        XCTAssertEqual(commentTags.first?.value, comment)
        
        // Verify proofs are in content (not encrypted for nutzaps)
        XCTAssertNotNil(nutzap.content)
        XCTAssertTrue(nutzap.content?.contains("proofs") ?? false)
    }
    
    func testValidateNutzapRecipient() throws {
        // Given
        let wallet = CashuWallet(name: "Recipient", mintURL: "https://mint.minibits.cash/Bitcoin")
        let nutzapEvent = Event(context: testContext)
        nutzapEvent.kind = EventKind.nutzap.rawValue
        
        // Add recipient tag
        nutzapEvent.allTags = [["p", KeyFixture.pubKeyHex]] as NSObject
        
        // When
        let isValid = wallet.canReceiveNutzap(nutzapEvent, recipientPubkey: KeyFixture.pubKeyHex)
        
        // Then
        XCTAssertTrue(isValid)
    }
}