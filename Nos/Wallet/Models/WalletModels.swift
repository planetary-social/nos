import Foundation

// MARK: - Wallet Models

/// Represents a Cashu wallet
struct WalletModel: Identifiable, Equatable {
    let id: UUID
    let seed: String
    let mnemonic: String
    let createdAt: Date
    var name: String?
}

/// Represents a Cashu mint
struct MintModel: Identifiable, Equatable {
    let id: UUID
    let url: URL
    let name: String
    let addedAt: Date
    var keysets: [KeysetModel] = []
    var balance: Int = 0
    var isActive: Bool = true
}

/// Represents a Cashu keyset
struct KeysetModel: Identifiable, Equatable {
    let id: UUID
    let keysetId: String
    let mint: MintModel
    let pubkey: String
    var unit: String = "sat"
}

/// Represents a proof of ecash
struct ProofModel: Identifiable, Equatable {
    let id: UUID
    let keysetId: String
    let C: String
    let secret: String
    let amount: Int
    let mintURL: URL
    
    enum State: String {
        case valid
        case pending
        case spent
    }
    
    var state: State = .valid
}

/// Represents a transaction
struct TransactionModel: Identifiable {
    let id: UUID
    let type: TransactionType
    let amount: Int
    let timestamp: Date
    let memo: String?
    var status: TransactionStatus = .pending
    var tokenData: String?
    
    enum TransactionType: String, Identifiable, CaseIterable {
        case mint
        case melt
        case send
        case receive
        
        var id: String { self.rawValue }
        
        var displayName: String {
            switch self {
            case .mint: return "Mint"
            case .melt: return "Pay"
            case .send: return "Send"
            case .receive: return "Receive"
            }
        }
        
        var iconName: String {
            switch self {
            case .mint: return "arrow.down.circle.fill"
            case .melt: return "bolt.fill"
            case .send: return "arrow.up.circle.fill"
            case .receive: return "arrow.down.circle.fill"
            }
        }
    }
    
    enum TransactionStatus: String {
        case pending
        case completed
        case failed
        
        var color: String {
            switch self {
            case .pending: return "yellow"
            case .completed: return "green"
            case .failed: return "red"
            }
        }
    }
}

/// Represents a token that can be sent or received
struct TokenModel: Identifiable {
    let id: UUID
    let token: String
    let amount: Int
    let mints: [URL]
    let memo: String?
    let createdAt: Date
}

// MARK: - NIP-60/61 Models

/// Represents a wallet connect request
struct WalletConnectRequest {
    let id: String
    let method: String
    let params: [String: Any]
    let origin: String
    let createdAt: Date
}

/// Represents a wallet connect response
struct WalletConnectResponse {
    let requestId: String
    let result: Result<[String: Any], Error>
    let createdAt: Date
}

/// Represents a Cashu-specific request
struct CashuRequest {
    let id: String
    let method: CashuMethod
    let params: [String: Any]
    let origin: String
    let createdAt: Date
    
    enum CashuMethod: String {
        case send
        case receive
        case mint
        case melt
        case info
    }
}

/// Represents a Cashu-specific response
struct CashuResponse {
    let requestId: String
    let result: Result<[String: Any], Error>
    let createdAt: Date
}