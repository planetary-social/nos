# CashuKit Technical Considerations for Nos

## Architecture Alignment

### Actor-Based Concurrency
CashuKit uses Swift actors for thread safety, which aligns perfectly with Nos's async/await patterns:

```swift
// CashuKit pattern
actor CashuWallet {
    private var tokens: [Token] = []
    
    func getBalance() async -> Int {
        tokens.reduce(0) { $0 + $1.amount }
    }
}

// Nos integration
class CashuWalletService: ObservableObject {
    private let wallet: CashuWallet
    @Published var balance: Int = 0
    
    func updateBalance() async {
        balance = await wallet.getBalance()
    }
}
```

### Core Data Integration Strategy

Map CashuKit's in-memory models to Core Data for persistence:

```swift
// Core Data entity
@objc(CashuTokenEntity)
public class CashuTokenEntity: NSManagedObject {
    @NSManaged public var proof: String
    @NSManaged public var amount: Int64
    @NSManaged public var mintURL: String
    @NSManaged public var secret: String
    @NSManaged public var c: String
    @NSManaged public var event: Event? // Link to Nostr event
}

// Adapter pattern
extension CashuToken {
    init(from entity: CashuTokenEntity) {
        self.init(
            amount: Int(entity.amount),
            proof: Proof(/* ... */),
            mint: URL(string: entity.mintURL)!
        )
    }
}
```

## NIP-60/61 Bridge Implementation

### Event Serialization
Create bidirectional converters between CashuKit types and Nostr events:

```swift
struct CashuEventBridge {
    // Wallet Event (17375)
    static func createWalletEvent(
        wallet: CashuWallet,
        keypair: Keypair
    ) async throws -> JSONEvent {
        let content = try await encryptWalletContent(wallet)
        return JSONEvent(
            pubkey: keypair.publicKey,
            createdAt: Date(),
            kind: .cashuWallet,
            tags: [["relays", /* wallet relays */]],
            content: content
        )
    }
    
    // Token Event (7375)
    static func createTokenEvent(
        tokens: [Token],
        mint: URL,
        keypair: Keypair
    ) async throws -> JSONEvent {
        let encrypted = try await encryptTokens(tokens)
        return JSONEvent(
            pubkey: keypair.publicKey,
            createdAt: Date(),
            kind: .cashuToken,
            tags: [["mint", mint.absoluteString]],
            content: encrypted
        )
    }
}
```

### State Synchronization
Implement relay sync with conflict resolution:

```swift
class CashuRelaySync {
    func syncWalletState() async throws {
        // 1. Fetch latest wallet events from relays
        let remoteEvents = try await fetchWalletEvents()
        
        // 2. Compare with local state
        let localTokens = try await loadLocalTokens()
        
        // 3. Resolve conflicts (newest wins)
        let mergedState = mergeStates(remote: remoteEvents, local: localTokens)
        
        // 4. Update local Core Data
        try await updateLocalState(mergedState)
        
        // 5. Publish changes if needed
        if hasLocalChanges {
            try await publishTokenEvents(mergedState)
        }
    }
}
```

## Security Implementation

### Keychain Wrapper for CashuKit
```swift
class CashuKeychainAdapter: CashuKeyStorage {
    private let keychain = KeychainSwift()
    
    func storeWalletSeed(_ seed: Data, walletId: String) throws {
        keychain.accessGroup = "group.nos.cashu"
        keychain.synchronizable = false
        
        guard keychain.set(seed, forKey: "cashu_wallet_\(walletId)") else {
            throw CashuError.keychainError
        }
    }
    
    func retrieveWalletSeed(walletId: String) throws -> Data {
        guard let seed = keychain.getData("cashu_wallet_\(walletId)") else {
            throw CashuError.walletNotFound
        }
        return seed
    }
}
```

### NIP-44 Encryption Integration
```swift
extension CashuWallet {
    func encryptForNostr(using keypair: Keypair) async throws -> String {
        let data = try JSONEncoder().encode(self.exportableState)
        return try NIP44Encryption.encrypt(
            plaintext: data,
            privateKey: keypair.privateKey,
            publicKey: keypair.publicKey
        )
    }
}
```

## Performance Optimizations

### Background Token Management
```swift
class CashuBackgroundManager {
    func scheduleTokenRefresh() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "nos.cashu.refresh",
            using: nil
        ) { task in
            Task {
                await self.refreshTokenStates()
                task.setTaskCompleted(success: true)
            }
        }
    }
    
    private func refreshTokenStates() async {
        // Check token validity
        // Rotate tokens if needed
        // Sync with relays
    }
}
```

### Efficient Balance Calculation
```swift
extension CashuWalletService {
    // Cache balance in Core Data
    @Published var cachedBalance: Int = 0
    
    func updateBalance() async {
        // Quick return cached value
        cachedBalance = UserDefaults.standard.integer(forKey: "cashu_balance")
        
        // Async update from source of truth
        let actualBalance = await wallet.getBalance()
        if actualBalance != cachedBalance {
            cachedBalance = actualBalance
            UserDefaults.standard.set(actualBalance, forKey: "cashu_balance")
        }
    }
}
```

## Error Handling Strategy

### Comprehensive Error Types
```swift
enum CashuNosError: LocalizedError {
    case walletNotInitialized
    case mintUnreachable(URL)
    case insufficientBalance(required: Int, available: Int)
    case relaySync(RelayError)
    case tokenExpired
    case invalidProof
    
    var errorDescription: String? {
        switch self {
        case .walletNotInitialized:
            return "Please set up your wallet first"
        case .mintUnreachable(let url):
            return "Cannot connect to mint: \(url.host ?? "")"
        case .insufficientBalance(let required, let available):
            return "Insufficient balance: need \(required), have \(available)"
        // ... etc
        }
    }
}
```

### Retry Logic with Backoff
```swift
class CashuNetworkManager {
    func executeWithRetry<T>(
        operation: () async throws -> T,
        maxRetries: Int = 3
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 0..<maxRetries {
            do {
                return try await operation()
            } catch {
                lastError = error
                let delay = pow(2.0, Double(attempt)) // Exponential backoff
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        
        throw lastError ?? CashuNosError.unknownError
    }
}
```

## Migration Path Preparation

### Abstract Wallet Interface
```swift
protocol NosWalletProtocol {
    associatedtype Token
    associatedtype Proof
    
    func createWallet() async throws
    func getBalance() async throws -> Int
    func mintTokens(amount: Int) async throws -> [Token]
    func sendTokens(amount: Int, to: PublicKey) async throws -> String
}

// Current implementation
class CashuKitWallet: NosWalletProtocol {
    typealias Token = CashuKit.Token
    typealias Proof = CashuKit.Proof
    // ... implementation
}

// Future CDK implementation
class CDKWallet: NosWalletProtocol {
    typealias Token = CDK.Token
    typealias Proof = CDK.Proof
    // ... implementation
}
```

## Testing Considerations

### Mock Mint for Development
```swift
#if DEBUG
class MockCashuMint: CashuMintProtocol {
    func requestMint(amount: Int) async throws -> MintQuote {
        // Return mock quote for testing
    }
    
    func mint(quote: MintQuote) async throws -> [Token] {
        // Return mock tokens
    }
}
#endif
```

### Integration Test Helpers
```swift
extension XCTestCase {
    func createTestWallet() async throws -> CashuWallet {
        let wallet = CashuWallet()
        try await wallet.addMint(URL(string: "https://testmint.cashu.space")!)
        return wallet
    }
    
    func assertTokenValid(_ token: Token) {
        XCTAssertNotNil(token.proof)
        XCTAssertGreaterThan(token.amount, 0)
        XCTAssertTrue(token.verify())
    }
}
```

## Monitoring & Analytics

### Wallet Health Metrics
```swift
struct CashuMetrics {
    static func trackWalletOperation(
        operation: String,
        success: Bool,
        duration: TimeInterval,
        error: Error? = nil
    ) {
        // Send to analytics
        Analytics.track("cashu_operation", properties: [
            "operation": operation,
            "success": success,
            "duration_ms": Int(duration * 1000),
            "error": error?.localizedDescription ?? ""
        ])
    }
}
```

## UI/UX Considerations

### SwiftUI State Management
```swift
@MainActor
class WalletViewModel: ObservableObject {
    @Published var balance: Int = 0
    @Published var isLoading = false
    @Published var error: CashuNosError?
    
    private let walletService: CashuWalletService
    
    func refreshBalance() async {
        isLoading = true
        error = nil
        
        do {
            balance = try await walletService.getBalance()
        } catch let cashuError as CashuNosError {
            error = cashuError
        } catch {
            error = .unknownError
        }
        
        isLoading = false
    }
}
```

This technical document provides specific implementation patterns and solutions for integrating CashuKit with Nos's architecture.