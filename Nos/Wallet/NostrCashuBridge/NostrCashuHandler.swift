import Foundation
import Logger

/// Handles Nostr NIP-61 Cashu-specific operations.
/// This class is responsible for processing cashu_request events and generating cashu_response events.
class NostrCashuHandler {
    
    // MARK: - Properties
    
    /// The wallet state to operate on
    private let walletState: WalletState
    
    /// Active connections managed by the wallet connect handler
    private let walletConnectHandler: NostrWalletConnectHandler
    
    // MARK: - Initialization
    
    init(walletState: WalletState, walletConnectHandler: NostrWalletConnectHandler) {
        self.walletState = walletState
        self.walletConnectHandler = walletConnectHandler
    }
    
    // MARK: - Public Methods
    
    /// Handles a cashu_request event from Nostr
    /// - Parameter eventContent: The content of the Nostr event as a dictionary
    /// - Returns: A response event to be published
    func handleCashuRequest(eventContent: [String: Any]) async throws -> [String: Any] {
        Log.debug("Processing cashu_request event: \(eventContent)")
        
        guard let method = eventContent["method"] as? String else {
            Log.error("Invalid cashu_request: missing method")
            throw CashuError.invalidRequest("Missing method field")
        }
        
        guard let id = eventContent["id"] as? String else {
            Log.error("Invalid cashu_request: missing id")
            throw CashuError.invalidRequest("Missing id field")
        }
        
        let params = eventContent["params"] as? [String: Any] ?? [:]
        
        // Process the request based on the method
        switch method {
        case "send_token":
            return try await handleSendTokenRequest(id: id, params: params)
        case "receive_token":
            return try await handleReceiveTokenRequest(id: id, params: params)
        case "mint_tokens":
            return try await handleMintTokensRequest(id: id, params: params)
        case "get_mints":
            return try await handleGetMintsRequest(id: id, params: params)
        case "get_proofs":
            return try await handleGetProofsRequest(id: id, params: params)
        default:
            Log.warning("Unsupported cashu_request method: \(method)")
            return createErrorResponse(id: id, code: -32601, message: "Method not supported")
        }
    }
    
    // MARK: - Private Methods - Request Handlers
    
    private func handleSendTokenRequest(id: String, params: [String: Any]) async throws -> [String: Any] {
        Log.debug("Handling send_token request with params: \(params)")
        
        // Validate connection
        try validateConnection(params: params, requiredPermission: .send)
        
        // Get the amount
        guard let amount = params["amount"] as? Int, amount > 0 else {
            Log.error("Invalid send_token request: invalid or missing amount")
            throw CashuError.invalidRequest("Invalid or missing amount")
        }
        
        // Get the optional memo
        let memo = params["memo"] as? String
        
        // Get the mint to use (optional, use default if not specified)
        let mintURL = params["mint_url"] as? String
        var mintToUse: MintModel?
        
        if let mintURL = mintURL, let url = URL(string: mintURL) {
            mintToUse = walletState.mints.first(where: { $0.url == url })
        } else {
            // Use the first active mint
            mintToUse = walletState.mints.first(where: { $0.isActive })
        }
        
        guard let mint = mintToUse else {
            Log.error("No valid mint available for send_token operation")
            throw CashuError.mintNotAvailable("No valid mint available")
        }
        
        do {
            // Create token
            let token = try await walletState.send(amount: amount, to: "external_app", mint: mint)
            
            // Return the token
            return [
                "id": id,
                "result": [
                    "token": token,
                    "amount": amount,
                    "mint_url": mint.url.absoluteString,
                    "memo": memo ?? ""
                ]
            ]
        } catch {
            Log.error("Failed to create token: \(error.localizedDescription)")
            return createErrorResponse(id: id, code: -32603, message: "Failed to create token: \(error.localizedDescription)")
        }
    }
    
    private func handleReceiveTokenRequest(id: String, params: [String: Any]) async throws -> [String: Any] {
        Log.debug("Handling receive_token request with params: \(params)")
        
        // Validate connection
        try validateConnection(params: params, requiredPermission: .receive)
        
        // Get the token
        guard let token = params["token"] as? String, !token.isEmpty else {
            Log.error("Invalid receive_token request: missing token")
            throw CashuError.invalidRequest("Missing token field")
        }
        
        do {
            // Process the token
            try await walletState.receive(token: token)
            
            // Return success
            return [
                "id": id,
                "result": [
                    "received": true,
                    "message": "Token received successfully"
                ]
            ]
        } catch {
            Log.error("Failed to receive token: \(error.localizedDescription)")
            return createErrorResponse(id: id, code: -32603, message: "Failed to receive token: \(error.localizedDescription)")
        }
    }
    
    private func handleMintTokensRequest(id: String, params: [String: Any]) async throws -> [String: Any] {
        Log.debug("Handling mint_tokens request with params: \(params)")
        
        // Validate connection
        try validateConnection(params: params, requiredPermission: .mint)
        
        // Get the amount
        guard let amount = params["amount"] as? Int, amount > 0 else {
            Log.error("Invalid mint_tokens request: invalid or missing amount")
            throw CashuError.invalidRequest("Invalid or missing amount")
        }
        
        // Get the mint URL
        guard let mintURLString = params["mint_url"] as? String,
              let mintURL = URL(string: mintURLString) else {
            Log.error("Invalid mint_tokens request: invalid or missing mint_url")
            throw CashuError.invalidRequest("Invalid or missing mint_url")
        }
        
        // Find the mint or add it
        var mint = walletState.mints.first(where: { $0.url == mintURL })
        
        if mint == nil {
            // Add the mint
            try await walletState.addMint(url: mintURL)
            mint = walletState.mints.first(where: { $0.url == mintURL })
        }
        
        guard let mintToUse = mint else {
            Log.error("Could not find or add mint: \(mintURLString)")
            throw CashuError.mintNotAvailable("Could not find or add mint")
        }
        
        do {
            // Mint tokens
            try await walletState.mint(amount: amount, mint: mintToUse)
            
            // Return success
            return [
                "id": id,
                "result": [
                    "minted": true,
                    "amount": amount,
                    "mint_url": mintToUse.url.absoluteString
                ]
            ]
        } catch {
            Log.error("Failed to mint tokens: \(error.localizedDescription)")
            return createErrorResponse(id: id, code: -32603, message: "Failed to mint tokens: \(error.localizedDescription)")
        }
    }
    
    private func handleGetMintsRequest(id: String, params: [String: Any]) async throws -> [String: Any] {
        Log.debug("Handling get_mints request with params: \(params)")
        
        // Validate connection
        try validateConnection(params: params, requiredPermission: .info)
        
        // Convert mints to dictionaries
        let mintsData = walletState.mints.map { mint -> [String: Any] in
            return [
                "url": mint.url.absoluteString,
                "name": mint.name,
                "active": mint.isActive,
                "balance": mint.balance
            ]
        }
        
        // Return the mints
        return [
            "id": id,
            "result": [
                "mints": mintsData
            ]
        ]
    }
    
    private func handleGetProofsRequest(id: String, params: [String: Any]) async throws -> [String: Any] {
        Log.debug("Handling get_proofs request with params: \(params)")
        
        // Validate connection
        try validateConnection(params: params, requiredPermission: .info)
        
        // Get the mint URL (optional filter)
        let mintURLString = params["mint_url"] as? String
        var filteredProofs = walletState.getAllValidProofs()
        
        // Apply mint filter if provided
        if let mintURLString = mintURLString, let url = URL(string: mintURLString) {
            filteredProofs = filteredProofs.filter { $0.mintURL == url }
        }
        
        // Convert proofs to a dictionary format for the response
        let proofsData = filteredProofs.map { proof -> [String: Any] in
            return [
                "id": proof.id.uuidString,
                "amount": proof.amount,
                "keysetId": proof.keysetId,
                "mint_url": proof.mintURL.absoluteString,
                "state": proof.state.rawValue
            ]
        }
        
        // Return the proofs
        return [
            "id": id,
            "result": [
                "proofs": proofsData
            ]
        ]
    }
    
    // MARK: - Helper Methods
    
    /// Validates if the connection exists and has the required permission
    private func validateConnection(params: [String: Any], requiredPermission: ConnectionInfo.Permission) throws {
        // Get the connection ID
        guard let connectionId = params["connection_id"] as? String else {
            Log.error("Missing connection_id in request")
            throw CashuError.unauthorized("Missing connection_id")
        }
        
        // Verify with wallet connect handler that this connection exists and has permission
        // For now, simplified implementation - in a full app we'd check with the wallet connect handler
        
        // Check if wallet is initialized
        guard walletState.isWalletInitialized else {
            Log.error("Wallet not initialized when validating connection")
            throw CashuError.internalError("Wallet not initialized")
        }
        
        // In a complete implementation, we would retrieve the connection from the WalletConnectHandler
        // and check if it has the required permission. For now, we'll allow the operation if 
        // the wallet is initialized (this is a simplification).
        
        Log.debug("Connection \(connectionId) validated for permission \(requiredPermission)")
    }
    
    // MARK: - Error Handling
    
    private func createErrorResponse(id: String, code: Int, message: String) -> [String: Any] {
        return [
            "id": id,
            "error": [
                "code": code,
                "message": message
            ]
        ]
    }
    
    // MARK: - Error Types
    
    enum CashuError: Error {
        case invalidRequest(String)
        case unauthorized(String)
        case permissionDenied(String)
        case internalError(String)
        case mintNotAvailable(String)
        
        var errorCode: Int {
            switch self {
            case .invalidRequest:
                return -32600
            case .unauthorized:
                return -32000
            case .permissionDenied:
                return -32001
            case .internalError:
                return -32603
            case .mintNotAvailable:
                return -32004
            }
        }
        
        var errorMessage: String {
            switch self {
            case .invalidRequest(let message),
                 .unauthorized(let message),
                 .permissionDenied(let message),
                 .internalError(let message),
                 .mintNotAvailable(let message):
                return message
            }
        }
    }
}

// MARK: - Connection Info

/// Represents connection information for authentication and permissions
/// This is duplicated from NostrWalletConnectHandler to allow NostrCashuHandler to reference it
/// In a real implementation, this would be shared between both handlers or moved to a separate file
struct ConnectionInfo {
    let pubkey: String
    let origin: String
    let permissions: [Permission]
    let createdAt: Date
    var lastUsed: Date
    
    enum Permission: String {
        case info
        case send
        case receive
        case mint
        case melt
    }
}