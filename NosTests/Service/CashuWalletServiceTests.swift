// ABOUTME: Tests for CashuWalletService which manages wallet operations and persistence
// ABOUTME: Covers wallet creation, loading, saving, and mint management

import XCTest
import CoreData
import Dependencies
@testable import Nos

final class CashuWalletServiceTests: CoreDataTestCase {
    
    @Dependency(\.currentUser) var currentUser
    var walletService: CashuWalletService!
    
    @MainActor override func setUp() async throws {
        try await super.setUp()
        walletService = CashuWalletService(context: testContext)
    }
    
    func testCreateWallet() async throws {
        // Given
        let user = try Author.findOrCreate(by: KeyFixture.pubKeyHex, context: testContext)
        let walletName = "My Test Wallet"
        let mintURL = "https://mint.minibits.cash/Bitcoin"
        
        // When
        let wallet = try await walletService.createWallet(
            name: walletName,
            mintURL: mintURL,
            for: user
        )
        
        // Then
        XCTAssertNotNil(wallet)
        XCTAssertEqual(wallet.name, walletName)
        XCTAssertEqual(wallet.mintURL, mintURL)
        
        // Verify wallet event was created
        let walletEvents = try await walletService.fetchWalletEvents(for: user)
        XCTAssertEqual(walletEvents.count, 1)
        XCTAssertEqual(walletEvents.first?.kind, EventKind.cashuWallet.rawValue)
    }
    
    func testLoadWalletsFromEvents() async throws {
        // Given
        let user = try Author.findOrCreate(by: KeyFixture.pubKeyHex, context: testContext)
        
        // Create a wallet and its event
        let wallet = CashuWallet(name: "Saved Wallet", mintURL: "https://mint.minibits.cash/Bitcoin")
        let walletEvent = try wallet.createWalletEvent(author: user)
        try testContext.save()
        
        // When
        let loadedWallets = try await walletService.loadWallets(for: user)
        
        // Then
        XCTAssertEqual(loadedWallets.count, 1)
        XCTAssertEqual(loadedWallets.first?.name, "Saved Wallet")
        XCTAssertEqual(loadedWallets.first?.mintURL, "https://mint.minibits.cash/Bitcoin")
    }
    
    func testSaveTokens() async throws {
        // Given
        let user = try Author.findOrCreate(by: KeyFixture.pubKeyHex, context: testContext)
        let wallet = CashuWallet(name: "Token Wallet", mintURL: "https://mint.minibits.cash/Bitcoin")
        let proofs = [
            CashuProof(amount: 1, id: "id1", secret: "secret1", C: "C1"),
            CashuProof(amount: 4, id: "id2", secret: "secret2", C: "C2")
        ]
        
        // When
        try await walletService.saveTokens(proofs, for: wallet, mint: wallet.mintURL, author: user)
        
        // Then
        let tokenEvents = try await walletService.fetchTokenEvents(for: user, mint: wallet.mintURL)
        XCTAssertEqual(tokenEvents.count, 1)
        XCTAssertEqual(tokenEvents.first?.kind, EventKind.cashuToken.rawValue)
        
        // Verify mint tag
        let tags = tokenEvents.first?.allTags as? [[String]] ?? []
        let mintTags = tags.filter { $0.first == "mint" }
        XCTAssertEqual(mintTags.first?[1], wallet.mintURL)
    }
    
    func testDeleteSpentTokens() async throws {
        // Given
        let user = try Author.findOrCreate(by: KeyFixture.pubKeyHex, context: testContext)
        let wallet = CashuWallet(name: "Spending Wallet", mintURL: "https://mint.minibits.cash/Bitcoin")
        
        // Create a token event
        let proofs = [CashuProof(amount: 8, id: "spent-id", secret: "spent-secret", C: "spent-C")]
        let tokenEvent = try wallet.createTokenEvent(proofs: proofs, mint: wallet.mintURL, author: user)
        try testContext.save()
        
        // When
        try await walletService.markTokensAsSpent(tokenEvent, author: user)
        
        // Then
        // Verify deletion event was created
        let deletionEvents = Event.all(context: testContext).filter { $0.kind == EventKind.delete.rawValue }
        XCTAssertEqual(deletionEvents.count, 1)
        
        // Verify it references the spent token
        let tags = deletionEvents.first?.allTags as? [[String]] ?? []
        let eventTags = tags.filter { $0.first == "e" }
        XCTAssertEqual(eventTags.first?[1], tokenEvent.identifier)
    }
    
    func testGetWalletBalance() async throws {
        // Given
        let user = try Author.findOrCreate(by: KeyFixture.pubKeyHex, context: testContext)
        let wallet = CashuWallet(name: "Balance Wallet", mintURL: "https://mint.minibits.cash/Bitcoin")
        
        // Create multiple token events
        let proofs1 = [
            CashuProof(amount: 1, id: "id1", secret: "secret1", C: "C1"),
            CashuProof(amount: 4, id: "id2", secret: "secret2", C: "C2")
        ]
        let proofs2 = [
            CashuProof(amount: 16, id: "id3", secret: "secret3", C: "C3")
        ]
        
        try await walletService.saveTokens(proofs1, for: wallet, mint: wallet.mintURL, author: user)
        try await walletService.saveTokens(proofs2, for: wallet, mint: wallet.mintURL, author: user)
        
        // When
        let balance = try await walletService.getBalance(for: wallet, author: user)
        
        // Then
        XCTAssertEqual(balance, 21) // 1 + 4 + 16
    }
}