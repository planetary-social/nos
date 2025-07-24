# CashuSwift Integration Plan

## Current Status (Updated: 2025-07-23)

### ✅ Completed
We have successfully removed the mock CashuProof type and prepared the codebase to use real CashuSwift types. The following changes have been made:

1. ✅ Removed mock `CashuProof` struct from `CashuWallet.swift`
2. ✅ Updated method signatures to use `Token` type instead of `CashuProof`
3. ✅ Created `CashuSwiftIntegration.swift` with real implementations
4. ✅ Updated `CashuWalletService` and `NutzapService` to use new types
5. ✅ Added `CashuSwiftConverter` for type conversions
6. ✅ Implemented core CashuSwift operations (mint, melt, P2PK lock)
7. ✅ Created proper Token serialization/deserialization

### 🚧 Remaining Issues
1. **Type Definitions**: The actual CashuSwift types (Token, Proof, Mint) need to be verified against the real library
2. **Wallet Storage**: Need to implement proper storage and retrieval of tokens
3. **Error Handling**: Need to map CashuSwift errors to our error types
4. **Testing**: All implementations need to be tested with the actual library
5. **Async Propagation**: Methods calling async CashuSwift operations need to be made async throughout the call chain

## Next Steps

### 1. Understand CashuSwift API (High Priority)
- [x] Study CashuSwift documentation and examples
- [x] Identify the correct types and methods to use:
  - Token structure and serialization
  - Wallet initialization
  - Mint operations (mint, melt, split)
  - P2PK locking/unlocking
  - Proof validation

### 2. Implement CashuSwiftConverter (High Priority)
- [x] Implement `tokenToJSON` method with proper Token serialization
- [x] Implement `jsonToToken` method with proper Token deserialization
- [ ] Add unit tests for converter methods
- [ ] Ensure compatibility with NIP-60 token format

### 3. Implement Wallet Initialization (High Priority)
- [ ] Update `CashuWallet.init` to create actual CashuSwift Wallet instance
- [x] Implement `initializeCashuSwiftWallet` method
- [ ] Handle mint connection and key setup
- [ ] Add error handling for initialization failures

### 4. Implement Core Operations (High Priority)
- [x] Implement `mintTokens` - Lightning to Cashu conversion
- [x] Implement `meltTokens` - Cashu to Lightning conversion
- [x] Implement `createP2PKLockedTokens` for nutzaps
- [ ] Implement `redeemP2PKTokens` for receiving nutzaps
- [ ] Implement `getBalance` to query mint balances
- [ ] Implement `validateProofs` to check token validity

### 5. Update Event Creation Methods
- [ ] Update `createTokenEvent` to properly serialize CashuSwift tokens
- [ ] Update `createNutzap` to use real P2PK locking
- [ ] Add proper NIP-44 encryption for wallet content
- [ ] Ensure backward compatibility with existing events

### 6. Update Service Layer
- [ ] Update `CashuWalletService` to handle async wallet operations
- [ ] Update `NutzapService` to use real P2PK operations
- [ ] Add proper error handling and retry logic
- [ ] Implement transaction history tracking

### 7. Testing
- [ ] Update unit tests to use real Token types
- [ ] Create integration tests with test mint
- [ ] Test P2PK locking/unlocking flow
- [ ] Test multi-mint scenarios
- [ ] Test error recovery scenarios

## Technical Challenges

1. **Token Serialization**: Need to ensure Token objects can be serialized to JSON format compatible with NIP-60
2. **Async Operations**: Most CashuSwift operations are async, need to propagate async/await through the stack
3. **Error Handling**: Need comprehensive error handling for network failures, invalid proofs, etc.
4. **Key Management**: P2PK operations require careful key management separate from Nostr keys
5. **Multi-Mint Support**: Need to manage connections to multiple mints efficiently

## Dependencies

- CashuSwift package from https://github.com/zeugmaster/CashuSwift
- Existing Nostr event system
- Core Data for persistence
- Keychain for secure storage

## Success Criteria

1. Can create and restore wallets from Nostr events
2. Can mint tokens from Lightning invoices
3. Can send and receive nutzaps with P2PK locking
4. Can manage tokens across multiple mints
5. All existing tests pass with real implementation
6. No regression in app functionality