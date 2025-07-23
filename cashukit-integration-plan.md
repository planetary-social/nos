# CashuKit Integration Plan for Nos

## Overview

This document outlines a detailed implementation plan for integrating CashuKit into Nos to add Cashu wallet support with NIP-60/61 compatibility.

## Pre-Implementation Phase (Week 0)

### 1. Fork and Setup
- [ ] Fork CashuKit to Nos organization
- [ ] Set up CI/CD for the fork
- [ ] Create integration branch in Nos
- [ ] Add CashuKit as Swift Package dependency
- [ ] Verify build compatibility with Nos

### 2. Architecture Design
- [ ] Design wallet abstraction protocol for future CDK migration
- [ ] Plan Core Data schema extensions
- [ ] Design service layer architecture
- [ ] Create technical design document

## Phase 1: Core Integration (Weeks 1-2)

### Week 1: Foundation

#### Day 1-2: Event System Integration
```swift
// Add to EventKind.swift
case cashuWallet = 17375
case cashuToken = 7375
case cashuSpendingHistory = 7376
case nutzapInfo = 10019
case nutzap = 9321
```

- [ ] Update EventKind enum
- [ ] Add event parsing in EventProcessor
- [ ] Create JSON event builders for Cashu events
- [ ] Add unit tests for event parsing

#### Day 3-4: Core Data Models
```swift
// New Core Data entities
- CashuWallet (wallet configuration)
- CashuToken (token storage)
- CashuMint (mint information)
- CashuTransaction (transaction history)
```

- [ ] Create Core Data model file
- [ ] Add relationships to existing entities
- [ ] Create migration plan
- [ ] Implement Core Data extensions

#### Day 5: Wallet Protocol & Service Layer
```swift
protocol CashuWalletProtocol {
    func createWallet() async throws -> CashuWallet
    func restoreWallet(mnemonic: String) async throws -> CashuWallet
    func getBalance() async throws -> Int
    func mintTokens(amount: Int) async throws -> [Token]
    func sendTokens(amount: Int, to: PublicKey) async throws -> String
}
```

- [ ] Define wallet abstraction protocol
- [ ] Create CashuKitAdapter implementing protocol
- [ ] Implement basic wallet service
- [ ] Add dependency injection setup

### Week 2: NIP-60 Implementation

#### Day 1-2: Wallet State Management
- [ ] Implement wallet event (17375) creation/parsing
- [ ] Add encryption for wallet private key (NIP-44)
- [ ] Create relay sync for wallet events
- [ ] Implement wallet discovery from relays

#### Day 3-4: Token Management
- [ ] Implement token event (7375) handling
- [ ] Add token state transitions (spend/rollover)
- [ ] Create proof validation logic
- [ ] Implement NIP-09 deletion for spent tokens

#### Day 5: Spending History
- [ ] Implement spending history events (7376)
- [ ] Create transaction tracking
- [ ] Add transaction categorization
- [ ] Build history query methods

## Phase 2: NIP-61 & Advanced Features (Week 3)

### Day 1-2: Nutzap Infrastructure
- [ ] Implement nutzap info event (10019)
- [ ] Add P2PK public key generation
- [ ] Create mint preference management
- [ ] Update user profile with nutzap info

### Day 3-4: Nutzap Send/Receive
- [ ] Implement nutzap event (9321) creation
- [ ] Add token locking with P2PK
- [ ] Create nutzap receiving logic
- [ ] Integrate with existing zap UI

### Day 5: Multi-Mint Support
- [ ] Implement mint discovery
- [ ] Add mint trust management
- [ ] Create mint switching logic
- [ ] Build mint health monitoring

## Phase 3: UI Implementation (Week 4)

### Day 1-2: Wallet Setup UI
```swift
// New Views
- WalletSetupView (create/restore)
- MnemonicBackupView
- MintSelectionView
```

- [ ] Create wallet onboarding flow
- [ ] Add mnemonic generation/display
- [ ] Build restore wallet UI
- [ ] Implement mint selection

### Day 3-4: Main Wallet UI
```swift
// Wallet Management Views
- WalletView (main wallet screen)
- BalanceView (balance display)
- SendReceiveView
- TransactionHistoryView
```

- [ ] Add wallet tab/section to settings
- [ ] Create balance display component
- [ ] Build send/receive flows
- [ ] Implement transaction history

### Day 5: Integration Points
- [ ] Add balance to user profile
- [ ] Integrate nutzaps with post actions
- [ ] Update notification system
- [ ] Add wallet status indicators

## Phase 4: Security & Production Hardening (Week 5)

### Day 1-2: Keychain Integration
```swift
// Secure storage implementation
class CashuKeychainManager {
    func storeWalletKey(_ key: Data, walletId: String)
    func retrieveWalletKey(walletId: String) -> Data?
    func deleteWalletKey(walletId: String)
}
```

- [ ] Implement secure key storage
- [ ] Add biometric authentication
- [ ] Create key backup/recovery
- [ ] Build security audit trail

### Day 3-4: Error Handling & Recovery
- [ ] Implement comprehensive error types
- [ ] Add retry logic for network failures
- [ ] Create recovery mechanisms
- [ ] Build user-friendly error messages

### Day 5: Performance & Optimization
- [ ] Add caching for token states
- [ ] Implement background sync
- [ ] Optimize Core Data queries
- [ ] Add performance monitoring

## Testing & Validation (Throughout)

### Unit Tests
- [ ] Event parsing tests
- [ ] Wallet operation tests
- [ ] Token validation tests
- [ ] Core Data tests

### Integration Tests
- [ ] Relay communication tests
- [ ] Multi-mint scenarios
- [ ] Nutzap flow tests
- [ ] Error recovery tests

### UI Tests
- [ ] Wallet creation flow
- [ ] Send/receive operations
- [ ] Error state handling
- [ ] Performance benchmarks

## Risk Mitigation Strategies

### 1. CashuKit Instability
- Maintain fork with stable commit
- Abstract all CashuKit calls
- Create fallback mechanisms
- Document workarounds

### 2. Protocol Changes
- Monitor NIP-60/61 discussions
- Design flexible event parsing
- Version wallet state
- Plan migration strategies

### 3. Security Vulnerabilities
- Regular security audits
- Implement defense in depth
- Use iOS security features
- Monitor for exploits

## Success Metrics

- [ ] Wallet creation < 5 seconds
- [ ] Token operations < 2 seconds
- [ ] 99.9% operation success rate
- [ ] Zero security incidents
- [ ] Positive user feedback

## Dependencies & Resources

### External Dependencies
- CashuKit (forked version)
- Existing Nos dependencies

### Team Resources
- 1-2 iOS developers
- Security reviewer
- UX designer for wallet flows
- QA tester

### Community Resources
- Cashu Discord/Telegram
- NIP authors
- CashuKit maintainers
- Nos community testers

## Post-Launch Plan

### Week 6+: Monitoring & Iteration
- Monitor wallet usage metrics
- Gather user feedback
- Fix bugs and edge cases
- Plan feature enhancements

### Future Enhancements
- [ ] Advanced mint selection algorithms
- [ ] Automated backup strategies
- [ ] Cross-device wallet sync
- [ ] Lightning Network integration
- [ ] Migration to CDK when available

## Communication Plan

### Internal
- Daily standups during implementation
- Weekly progress reports
- Architecture decision records
- Code review requirements

### External
- Blog post announcement
- Community beta testing
- Open source contributions
- Conference presentations

## Conclusion

This plan provides a structured approach to integrating CashuKit into Nos over 5 weeks, with clear milestones and risk mitigation strategies. The modular approach allows for adjustments based on discoveries during implementation while maintaining the overall timeline.