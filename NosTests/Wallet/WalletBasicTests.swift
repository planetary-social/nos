import XCTest
@testable import Nos

/// Basic tests for wallet functionality
final class WalletBasicTests: XCTestCase {
    
    func testWalletInitialState() {
        // Create wallet manager
        let manager = NosWalletManager()
        
        // Initial state should have an uninitialized wallet
        XCTAssertFalse(manager.isWalletInitialized)
        XCTAssertEqual(manager.balance, 0)
        XCTAssertTrue(manager.mints.isEmpty)
        XCTAssertTrue(manager.transactions.isEmpty)
    }
    
    func testWalletCreation() async throws {
        // Create wallet manager
        let manager = NosWalletManager()
        
        // Create a new wallet
        try await manager.createWallet()
        
        // Wallet should now be initialized
        XCTAssertTrue(manager.isWalletInitialized)
        
        // Balance should start at 0
        XCTAssertEqual(manager.balance, 0)
        
        // Should have default mints after initialization
        XCTAssertFalse(manager.mints.isEmpty)
    }
    
    func testNostrEventHandling() async throws {
        // Create wallet manager
        let manager = NosWalletManager()
        
        // Create a wallet first
        try await manager.createWallet()
        
        // Create a non-wallet event
        let regularEvent: [String: Any] = [
            "id": "regular-event-123",
            "kind": 1, // Regular text note
            "pubkey": "test-pubkey",
            "content": "Hello world!"
        ]
        
        // The manager should ignore non-wallet events
        let regularResponse = try await manager.handleNostrEvent(event: regularEvent)
        XCTAssertNil(regularResponse, "Regular events should be ignored")
        
        // Create a wallet request event
        let walletEvent: [String: Any] = [
            "id": "wallet-event-123",
            "kind": Nos.Wallet.NostrCashuBridge.WalletEventTypes.NIP60.walletRequestKind,
            "pubkey": "test-pubkey",
            "content": """
            {
                "id": "test-id-123",
                "method": "get_info",
                "params": {
                    "connection_id": "connection-123"
                }
            }
            """
        ]
        
        // The manager should process wallet events
        let walletResponse = try await manager.handleNostrEvent(event: walletEvent)
        XCTAssertNotNil(walletResponse, "Wallet events should be processed")
        XCTAssertEqual(walletResponse?["kind"] as? Int, Nos.Wallet.NostrCashuBridge.WalletEventTypes.NIP60.walletResponseKind)
    }
}