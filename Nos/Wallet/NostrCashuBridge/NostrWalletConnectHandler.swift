import Foundation
import Logger

/// Handles Nostr NIP-60 wallet connection protocol.
/// This class is responsible for processing wallet_request events and generating wallet_response events.
class NostrWalletConnectHandler {
    
    // MARK: - Properties
    
    /// The wallet state to operate on
    private let walletState: WalletState
    
    /// Active connections to external applications
    private var activeConnections: [String: ConnectionInfo] = [:]
    
    /// Structure to track connection information
    private struct ConnectionInfo {
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
    
    // MARK: - Initialization
    
    init(walletState: WalletState) {
        self.walletState = walletState
    }
    
    // MARK: - Public Methods
    
    /// Handles a wallet_request event from Nostr
    /// - Parameter eventContent: The content of the Nostr event as a dictionary
    /// - Returns: A response event to be published
    func handleWalletRequest(eventContent: [String: Any]) async throws -> [String: Any] {
        Log.debug("Processing wallet_request event: \(eventContent)")
        
        guard let method = eventContent["method"] as? String else {
            Log.error("Invalid wallet_request: missing method")
            throw WalletConnectError.invalidRequest("Missing method field")
        }
        
        guard let id = eventContent["id"] as? String else {
            Log.error("Invalid wallet_request: missing id")
            throw WalletConnectError.invalidRequest("Missing id field")
        }
        
        let params = eventContent["params"] as? [String: Any] ?? [:]
        
        // Process the request based on the method
        switch method {
        case "connect":
            return try await handleConnectRequest(id: id, params: params)
        case "get_info":
            return try await handleGetInfoRequest(id: id, params: params)
        case "get_balance":
            return try await handleGetBalanceRequest(id: id, params: params)
        case "pay":
            return try await handlePayRequest(id: id, params: params)
        default:
            Log.warning("Unsupported wallet_request method: \(method)")
            return createErrorResponse(id: id, code: -32601, message: "Method not supported")
        }
    }
    
    // MARK: - Private Methods - Request Handlers
    
    private func handleConnectRequest(id: String, params: [String: Any]) async throws -> [String: Any] {
        Log.debug("Handling connect request with params: \(params)")
        
        guard let origin = params["origin"] as? String else {
            Log.error("Invalid connect request: missing origin")
            throw WalletConnectError.invalidRequest("Missing origin field")
        }
        
        guard let pubkey = params["pubkey"] as? String else {
            Log.error("Invalid connect request: missing pubkey")
            throw WalletConnectError.invalidRequest("Missing pubkey field")
        }
        
        let requestedPermissions = (params["permissions"] as? [String]) ?? ["info"]
        let permissions = requestedPermissions.compactMap { 
            ConnectionInfo.Permission(rawValue: $0)
        }
        
        // Create a connection ID
        let connectionId = UUID().uuidString
        
        // Store the connection
        let connectionInfo = ConnectionInfo(
            pubkey: pubkey,
            origin: origin,
            permissions: permissions,
            createdAt: Date(),
            lastUsed: Date()
        )
        activeConnections[connectionId] = connectionInfo
        
        Log.info("New wallet connection established: \(connectionId) from \(origin)")
        
        // Return the successful response
        return [
            "id": id,
            "result": [
                "approved": true,
                "connection_id": connectionId,
                "permissions": permissions.map { $0.rawValue }
            ]
        ]
    }
    
    private func handleGetInfoRequest(id: String, params: [String: Any]) async throws -> [String: Any] {
        Log.debug("Handling get_info request with params: \(params)")
        
        guard let connectionId = params["connection_id"] as? String,
              let connection = activeConnections[connectionId] else {
            Log.error("Invalid get_info request: invalid connection_id")
            throw WalletConnectError.unauthorized("Invalid or expired connection")
        }
        
        // Check if the connection has the 'info' permission
        guard connection.permissions.contains(.info) else {
            Log.warning("Connection \(connectionId) tried to use 'info' permission without authorization")
            throw WalletConnectError.permissionDenied("The connection does not have 'info' permission")
        }
        
        // Update last used timestamp
        activeConnections[connectionId]?.lastUsed = Date()
        
        // Return wallet info
        return [
            "id": id,
            "result": [
                "name": "Nos Cashu Wallet",
                "version": "1.0.0",
                "supports": ["cashu"],
                "methods": connection.permissions.map { $0.rawValue }
            ]
        ]
    }
    
    private func handleGetBalanceRequest(id: String, params: [String: Any]) async throws -> [String: Any] {
        Log.debug("Handling get_balance request with params: \(params)")
        
        guard let connectionId = params["connection_id"] as? String,
              let connection = activeConnections[connectionId] else {
            Log.error("Invalid get_balance request: invalid connection_id")
            throw WalletConnectError.unauthorized("Invalid or expired connection")
        }
        
        // Check if the connection has the 'info' permission
        guard connection.permissions.contains(.info) else {
            Log.warning("Connection \(connectionId) tried to use 'info' permission without authorization")
            throw WalletConnectError.permissionDenied("The connection does not have 'info' permission")
        }
        
        // Update last used timestamp
        activeConnections[connectionId]?.lastUsed = Date()
        
        // Return wallet balance
        return [
            "id": id,
            "result": [
                "balance": walletState.balance,
                "currency": "sat"
            ]
        ]
    }
    
    private func handlePayRequest(id: String, params: [String: Any]) async throws -> [String: Any] {
        Log.debug("Handling pay request with params: \(params)")
        
        guard let connectionId = params["connection_id"] as? String,
              let connection = activeConnections[connectionId] else {
            Log.error("Invalid pay request: invalid connection_id")
            throw WalletConnectError.unauthorized("Invalid or expired connection")
        }
        
        // Check if the connection has the 'melt' permission
        guard connection.permissions.contains(.melt) else {
            Log.warning("Connection \(connectionId) tried to use 'melt' permission without authorization")
            throw WalletConnectError.permissionDenied("The connection does not have 'melt' permission")
        }
        
        // Get the invoice
        guard let invoice = params["invoice"] as? String else {
            Log.error("Invalid pay request: missing invoice")
            throw WalletConnectError.invalidRequest("Missing invoice field")
        }
        
        // Update last used timestamp
        activeConnections[connectionId]?.lastUsed = Date()
        
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
            Log.error("No valid mint available for pay operation")
            throw WalletConnectError.internalError("No valid mint available")
        }
        
        do {
            // Process the payment
            try await walletState.melt(invoice: invoice, mint: mint)
            
            // Return successful response
            return [
                "id": id,
                "result": [
                    "paid": true,
                    "invoice": invoice
                    // Note: preimage is not returned by Cashu protocol, only valid/invalid status
                ]
            ]
        } catch {
            Log.error("Failed to pay invoice: \(error.localizedDescription)")
            return createErrorResponse(id: id, code: -32603, message: "Failed to pay invoice: \(error.localizedDescription)")
        }
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
    
    enum WalletConnectError: Error {
        case invalidRequest(String)
        case unauthorized(String)
        case permissionDenied(String)
        case internalError(String)
        
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
            }
        }
        
        var errorMessage: String {
            switch self {
            case .invalidRequest(let message),
                 .unauthorized(let message),
                 .permissionDenied(let message),
                 .internalError(let message):
                return message
            }
        }
    }
}