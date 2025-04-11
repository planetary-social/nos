import XCTest
@testable import Nos

final class NostrCashuHandlerTests: XCTestCase {
    private var walletState: WalletState!
    private var walletConnectHandler: NostrWalletConnectHandler!
    private var cashuHandler: NostrCashuHandler!
    
    override func setUp() async throws {
        try await super.setUp()
        walletState = WalletState()
        try await walletState.createNewWallet()
        walletConnectHandler = NostrWalletConnectHandler(walletState: walletState)
        cashuHandler = NostrCashuHandler(walletState: walletState, walletConnectHandler: walletConnectHandler)
    }
    
    override func tearDown() async throws {
        walletState = nil
        walletConnectHandler = nil
        cashuHandler = nil
        try await super.tearDown()
    }
    
    func testHandleCashuRequest_InvalidRequest_ThrowsError() async throws {
        // Test missing method
        do {
            let eventContent: [String: Any] = [
                "id": "test-id-123"
            ]
            _ = try await cashuHandler.handleCashuRequest(eventContent: eventContent)
            XCTFail("Should have thrown an error for missing method")
        } catch let error as NostrCashuHandler.CashuError {
            XCTAssertEqual(error.errorCode, -32600)
        }
        
        // Test missing id
        do {
            let eventContent: [String: Any] = [
                "method": "send_token"
            ]
            _ = try await cashuHandler.handleCashuRequest(eventContent: eventContent)
            XCTFail("Should have thrown an error for missing id")
        } catch let error as NostrCashuHandler.CashuError {
            XCTAssertEqual(error.errorCode, -32600)
        }
    }
    
    func testHandleCashuRequest_UnsupportedMethod_ReturnsError() async throws {
        let eventContent: [String: Any] = [
            "id": "test-id-123",
            "method": "unsupported_method"
        ]
        
        let response = try await cashuHandler.handleCashuRequest(eventContent: eventContent)
        
        XCTAssertNotNil(response["error"])
        let error = response["error"] as? [String: Any]
        XCTAssertEqual(error?["code"] as? Int, -32601)
        XCTAssertEqual(error?["message"] as? String, "Method not supported")
    }
    
    func testHandleSendTokenRequest_ValidRequest_ReturnsToken() async throws {
        let eventContent: [String: Any] = [
            "id": "test-id-123",
            "method": "send_token",
            "params": [
                "amount": 1000,
                "memo": "Test payment"
            ]
        ]
        
        let response = try await cashuHandler.handleCashuRequest(eventContent: eventContent)
        
        XCTAssertNotNil(response["id"])
        XCTAssertEqual(response["id"] as? String, "test-id-123")
        
        let result = response["result"] as? [String: Any]
        XCTAssertNotNil(result)
        XCTAssertNotNil(result?["token"])
        XCTAssertEqual(result?["amount"] as? Int, 1000)
        XCTAssertEqual(result?["memo"] as? String, "Test payment")
    }
    
    func testHandleReceiveTokenRequest_ValidRequest_ReturnsSuccess() async throws {
        let eventContent: [String: Any] = [
            "id": "test-id-123",
            "method": "receive_token",
            "params": [
                "token": "test-token-data"
            ]
        ]
        
        let response = try await cashuHandler.handleCashuRequest(eventContent: eventContent)
        
        XCTAssertNotNil(response["id"])
        XCTAssertEqual(response["id"] as? String, "test-id-123")
        
        let result = response["result"] as? [String: Any]
        XCTAssertNotNil(result)
        XCTAssertEqual(result?["received"] as? Bool, true)
        XCTAssertNotNil(result?["message"])
    }
    
    func testHandleGetMintsRequest_ReturnsAvailableMints() async throws {
        let eventContent: [String: Any] = [
            "id": "test-id-123",
            "method": "get_mints",
            "params": [:]
        ]
        
        let response = try await cashuHandler.handleCashuRequest(eventContent: eventContent)
        
        XCTAssertNotNil(response["id"])
        XCTAssertEqual(response["id"] as? String, "test-id-123")
        
        let result = response["result"] as? [String: Any]
        XCTAssertNotNil(result)
        
        let mints = result?["mints"] as? [[String: Any]]
        XCTAssertNotNil(mints)
        // The wallet state initialization should add some default mints
        XCTAssertGreaterThan(mints?.count ?? 0, 0)
    }
    
    func testWalletEventTypes_CreateCashuResponseEvent() {
        let response = WalletEventTypes.createCashuResponseEvent(
            requestId: "request-123",
            pubkey: "pubkey-abc",
            response: ["status": "success"]
        )
        
        XCTAssertEqual(response["kind"] as? Int, WalletEventTypes.NIP61.cashuResponseKind)
        XCTAssertEqual(response["pubkey"] as? String, "pubkey-abc")
        XCTAssertNotNil(response["created_at"])
        
        let tags = response["tags"] as? [[String]]
        XCTAssertEqual(tags?.count, 1)
        XCTAssertEqual(tags?[0][0], "e")
        XCTAssertEqual(tags?[0][1], "request-123")
        
        // Content should be a JSON string containing our response
        let content = response["content"] as? String
        XCTAssertNotNil(content)
        XCTAssert(content?.contains("success") ?? false)
    }
}