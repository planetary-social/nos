// ABOUTME: Tests for NIP-60 wallet event creation and parsing
// ABOUTME: Ensures proper Nostr event structure for Cashu wallet data

import XCTest
import CoreData
@testable import Nos

final class CashuWalletEventTests: CoreDataTestCase {
    
    func testCreateWalletEvent() throws {
        // Given
        let wallet = CashuWallet(name: "Test Wallet", mintURL: "https://mint.minibits.cash/Bitcoin")
        let author = try Author.findOrCreate(by: KeyFixture.pubKeyHex, context: testContext)
        
        // When
        let walletEvent = try wallet.createWalletEvent(author: author)
        
        // Then
        XCTAssertEqual(walletEvent.kind, EventKind.cashuWallet.rawValue)
        XCTAssertEqual(walletEvent.author, author)
        
        // Verify tags
        let tags = walletEvent.allTags as? [[String]] ?? []
        
        let mintTags = tags.filter { $0.first == "mint" }
        XCTAssertEqual(mintTags.count, 1)
        XCTAssertEqual(mintTags.first?[1], wallet.mintURL)
        
        let nameTags = tags.filter { $0.first == "name" }
        XCTAssertEqual(nameTags.count, 1)
        XCTAssertEqual(nameTags.first?[1], wallet.name)
        
        let pubkeyTags = tags.filter { $0.first == "pubkey" }
        XCTAssertEqual(pubkeyTags.count, 1)
        XCTAssertEqual(pubkeyTags.first?[1], wallet.walletPublicKey)
        
        // Verify content is encrypted
        XCTAssertNotNil(walletEvent.content)
        XCTAssertNotEqual(walletEvent.content, wallet.walletPrivateKey)
        XCTAssertTrue(walletEvent.content?.count ?? 0 > 50) // Encrypted content should be longer
    }
    
    func testCreateTokenEvent() throws {
        // Given
        let wallet = CashuWallet(name: "Test Wallet", mintURL: "https://mint.minibits.cash/Bitcoin")
        let author = try Author.findOrCreate(by: KeyFixture.pubKeyHex, context: testContext)
        let mockProofs = [
            CashuProof(amount: 1, id: "test-id", secret: "test-secret", C: "test-C"),
            CashuProof(amount: 2, id: "test-id", secret: "test-secret-2", C: "test-C-2")
        ]
        
        // When
        let tokenEvent = try wallet.createTokenEvent(proofs: mockProofs, mint: wallet.mintURL, author: author)
        
        // Then
        XCTAssertEqual(tokenEvent.kind, EventKind.cashuToken.rawValue)
        XCTAssertEqual(tokenEvent.author, author)
        
        // Verify mint tag
        let tags = tokenEvent.allTags as? [[String]] ?? []
        let mintTags = tags.filter { $0.first == "mint" }
        XCTAssertEqual(mintTags.count, 1)
        XCTAssertEqual(mintTags.first?[1], wallet.mintURL)
        
        // Verify content is encrypted
        XCTAssertNotNil(tokenEvent.content)
        XCTAssertTrue(tokenEvent.content?.contains("test-secret") == false) // Should be encrypted
    }
}

