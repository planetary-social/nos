import XCTest
@testable import Nos

final class NosWalletManagerTests: XCTestCase {
    private var walletManager: NosWalletManager!
    
    override func setUp() {
        super.setUp()
        walletManager = NosWalletManager()
    }
    
    override func tearDown() {
        walletManager = nil
        super.tearDown()
    }
    
    func testInitialState() {
        // Initial state should be wallet not initialized
        XCTAssertFalse(walletManager.isWalletInitialized)
        XCTAssertEqual(walletManager.balance, 0)
        XCTAssertTrue(walletManager.mints.isEmpty)
        XCTAssertTrue(walletManager.transactions.isEmpty)
    }
    
    func testCreateWallet() async throws {
        // Create a new wallet
        try await walletManager.createWallet()
        
        // After creation, wallet should be initialized
        XCTAssertTrue(walletManager.isWalletInitialized)
        
        // Should have default mints added
        XCTAssertFalse(walletManager.mints.isEmpty)
        
        // Balance should still be 0 initially
        XCTAssertEqual(walletManager.balance, 0)
    }
    
    func testSendAndReceiveTokens() async throws {
        try await walletManager.createWallet()
        
        // Get one of the default mints
        guard let mint = walletManager.mints.first else {
            XCTFail("No mint available")
            return
        }
        
        // Send tokens (creates a token)
        let token = try await walletManager.sendTokens(amount: 500, to: "test-receiver", mint: mint)
        XCTAssertFalse(token.isEmpty)
        
        // Transaction should be added and balance reduced
        let sendTransaction = walletManager.transactions.first(where: { $0.type == .send })
        XCTAssertNotNil(sendTransaction)
        XCTAssertEqual(sendTransaction?.amount, 500)
        
        // Receive tokens (redeems a token)
        try await walletManager.receiveTokens(token: token)
        
        // Transaction should be added and balance increased
        let receiveTransaction = walletManager.transactions.first(where: { $0.type == .receive })
        XCTAssertNotNil(receiveTransaction)
        
        // Test mint operations
        try await walletManager.mintTokens(amount: 1000, mint: mint)
        
        // Transaction should be added and balance increased
        let mintTransaction = walletManager.transactions.first(where: { $0.type == .mint })
        XCTAssertNotNil(mintTransaction)
        XCTAssertEqual(mintTransaction?.amount, 1000)
    }
    
    func testHandleNostrEvent_WalletRequest() async throws {
        try await walletManager.createWallet()
        
        // Create a wallet request event
        let event: [String: Any] = [
            "id": "req-123",
            "kind": WalletEventTypes.NIP60.walletRequestKind,
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
        
        // Process the event
        let responseEvent = try await walletManager.handleNostrEvent(event: event)
        
        // Should get a response event
        XCTAssertNotNil(responseEvent)
        XCTAssertEqual(responseEvent?["kind"] as? Int, WalletEventTypes.NIP60.walletResponseKind)
        XCTAssertEqual(responseEvent?["pubkey"] as? String, "test-pubkey")
    }
    
    func testHandleNostrEvent_CashuRequest() async throws {
        try await walletManager.createWallet()
        
        // Create a cashu request event
        let event: [String: Any] = [
            "id": "req-123",
            "kind": WalletEventTypes.NIP61.cashuRequestKind,
            "pubkey": "test-pubkey",
            "content": """
            {
                "id": "test-id-123",
                "method": "get_mints",
                "params": {}
            }
            """
        ]
        
        // Process the event
        let responseEvent = try await walletManager.handleNostrEvent(event: event)
        
        // Should get a response event
        XCTAssertNotNil(responseEvent)
        XCTAssertEqual(responseEvent?["kind"] as? Int, WalletEventTypes.NIP61.cashuResponseKind)
        XCTAssertEqual(responseEvent?["pubkey"] as? String, "test-pubkey")
    }
    
    func testHandleNostrEvent_UnrelatedEvent() async throws {
        try await walletManager.createWallet()
        
        // Create a different kind of event
        let event: [String: Any] = [
            "id": "event-123",
            "kind": 1, // Text note
            "pubkey": "test-pubkey",
            "content": "Hello world!"
        ]
        
        // Process the event
        let responseEvent = try await walletManager.handleNostrEvent(event: event)
        
        // Should not get a response event since this isn't wallet-related
        XCTAssertNil(responseEvent)
    }
}