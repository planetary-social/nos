import Foundation

/// Contains definitions and utility functions for NIP-60/61 Nostr event types
enum WalletEventTypes {
    
    // MARK: - Event Types
    
    /// NIP-60 Wallet Connect Event Types
    enum NIP60 {
        /// Event kind for wallet request (client -> wallet)
        static let walletRequestKind = 13194
        
        /// Event kind for wallet response (wallet -> client)
        static let walletResponseKind = 13195
    }
    
    /// NIP-61 Cashu Event Types
    enum NIP61 {
        /// Event kind for Cashu request (client -> wallet)
        static let cashuRequestKind = 13196
        
        /// Event kind for Cashu response (wallet -> client)
        static let cashuResponseKind = 13197
    }
    
    // MARK: - Event Creation Helpers
    
    /// Creates a wallet_response event in response to a wallet_request
    /// - Parameters:
    ///   - requestId: The ID of the request being responded to
    ///   - pubkey: The pubkey of the wallet
    ///   - response: The response data as a dictionary
    /// - Returns: Dictionary representing the event content
    static func createWalletResponseEvent(requestId: String, pubkey: String, response: [String: Any]) -> [String: Any] {
        let timestamp = Int(Date().timeIntervalSince1970)
        
        return [
            "kind": NIP60.walletResponseKind,
            "pubkey": pubkey,
            "created_at": timestamp,
            "tags": [
                ["e", requestId]
            ],
            "content": jsonEncode(response) ?? "{}"
        ]
    }
    
    /// Creates a cashu_response event in response to a cashu_request
    /// - Parameters:
    ///   - requestId: The ID of the request being responded to
    ///   - pubkey: The pubkey of the wallet
    ///   - response: The response data as a dictionary
    /// - Returns: Dictionary representing the event content
    static func createCashuResponseEvent(requestId: String, pubkey: String, response: [String: Any]) -> [String: Any] {
        let timestamp = Int(Date().timeIntervalSince1970)
        
        return [
            "kind": NIP61.cashuResponseKind,
            "pubkey": pubkey,
            "created_at": timestamp,
            "tags": [
                ["e", requestId]
            ],
            "content": jsonEncode(response) ?? "{}"
        ]
    }
    
    // MARK: - Event Parsing Helpers
    
    /// Parses a wallet_request event content
    /// - Parameter eventContent: The content of the event
    /// - Returns: Dictionary containing the parsed request data
    static func parseWalletRequestEvent(eventContent: String) -> [String: Any]? {
        return jsonDecode(eventContent)
    }
    
    /// Parses a cashu_request event content
    /// - Parameter eventContent: The content of the event
    /// - Returns: Dictionary containing the parsed request data
    static func parseCashuRequestEvent(eventContent: String) -> [String: Any]? {
        return jsonDecode(eventContent)
    }
    
    // MARK: - Utility Methods
    
    /// Encodes a dictionary to a JSON string
    /// - Parameter dict: The dictionary to encode
    /// - Returns: JSON string representation or nil if encoding fails
    private static func jsonEncode(_ dict: [String: Any]) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: dict, options: []) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
    
    /// Decodes a JSON string to a dictionary
    /// - Parameter jsonString: The JSON string to decode
    /// - Returns: Dictionary representation or nil if decoding fails
    private static func jsonDecode(_ jsonString: String) -> [String: Any]? {
        guard let data = jsonString.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return nil
        }
        return dict
    }
}