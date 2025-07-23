# CashuKit Implementation Checklist

## Quick Reference Implementation Tracker

### 🚀 Week 0: Pre-Implementation
- [ ] Fork CashuKit repository
- [ ] Set up development branch: `terragon/add-wallet-support-nip60-nip61-cashu`
- [ ] Add CashuKit as SPM dependency
- [ ] Verify successful build with Nos
- [ ] Create architecture design doc

### 📱 Week 1: Core Integration

#### Event System (Day 1-2)
- [ ] Add 5 new event kinds to `EventKind.swift`
- [ ] Update `EventProcessor.parse()` for Cashu events
- [ ] Create `CashuEventBuilder` helper class
- [ ] Write unit tests for event parsing

#### Core Data (Day 3-4)
- [ ] Create `Nos.xcdatamodeld` updates
- [ ] Add `CashuWallet` entity
- [ ] Add `CashuToken` entity
- [ ] Add `CashuMint` entity
- [ ] Add `CashuTransaction` entity
- [ ] Create Core Data migration
- [ ] Test migration on existing database

#### Service Layer (Day 5)
- [ ] Define `CashuWalletProtocol`
- [ ] Create `CashuKitAdapter` class
- [ ] Implement `CashuWalletService`
- [ ] Add to dependency injection

### 🔐 Week 2: NIP-60 Implementation

#### Wallet State (Day 1-2)
- [ ] Implement wallet event creation (17375)
- [ ] Add NIP-44 encryption for wallet content
- [ ] Create relay sync for wallet events
- [ ] Implement wallet discovery

#### Token Management (Day 3-4)
- [ ] Handle token events (7375)
- [ ] Implement token state transitions
- [ ] Add proof validation
- [ ] Create NIP-09 deletion logic

#### History Tracking (Day 5)
- [ ] Add spending history events (7376)
- [ ] Create transaction categorization
- [ ] Build history queries
- [ ] Test history accuracy

### ⚡ Week 3: NIP-61 & Advanced

#### Nutzap Setup (Day 1-2)
- [ ] Create nutzap info events (10019)
- [ ] Generate P2PK keys
- [ ] Add mint preferences
- [ ] Update user profile

#### Nutzap Flow (Day 3-4)
- [ ] Build nutzap events (9321)
- [ ] Implement P2PK locking
- [ ] Create receiving logic
- [ ] Integrate with zap UI

#### Multi-Mint (Day 5)
- [ ] Add mint discovery
- [ ] Create trust management
- [ ] Build switching logic
- [ ] Add health monitoring

### 🎨 Week 4: UI Implementation

#### Setup UI (Day 1-2)
- [ ] Create `WalletSetupView`
- [ ] Build `MnemonicBackupView`
- [ ] Add `MintSelectionView`
- [ ] Implement onboarding flow

#### Main UI (Day 3-4)
- [ ] Create `WalletView`
- [ ] Build `BalanceView` component
- [ ] Add `SendReceiveView`
- [ ] Create `TransactionHistoryView`

#### Integration (Day 5)
- [ ] Add balance to profile
- [ ] Update post action sheet
- [ ] Enhance notifications
- [ ] Add status indicators

### 🛡️ Week 5: Security & Polish

#### Security (Day 1-2)
- [ ] Implement Keychain storage
- [ ] Add biometric auth
- [ ] Create backup flow
- [ ] Build audit logging

#### Error Handling (Day 3-4)
- [ ] Define error types
- [ ] Add retry logic
- [ ] Create recovery flows
- [ ] Write user messages

#### Performance (Day 5)
- [ ] Add token caching
- [ ] Implement background sync
- [ ] Optimize queries
- [ ] Add monitoring

### ✅ Testing Throughout

#### Unit Tests
- [ ] Event parsing tests
- [ ] Wallet operation tests
- [ ] Token validation tests
- [ ] Core Data tests

#### Integration Tests
- [ ] Relay communication
- [ ] Multi-mint scenarios
- [ ] Nutzap flows
- [ ] Error recovery

#### UI Tests
- [ ] Wallet creation
- [ ] Send/receive ops
- [ ] Error states
- [ ] Performance

### 📊 Success Criteria
- [ ] Wallet creation < 5 seconds
- [ ] Token operations < 2 seconds
- [ ] 99.9% success rate
- [ ] Zero security incidents
- [ ] Positive user feedback

### 🚨 Blockers Log
Use this section to track any blockers encountered:

```
Date: [YYYY-MM-DD]
Blocker: [Description]
Impact: [What's blocked]
Resolution: [How it was resolved]
```

### 📝 Daily Standup Template
```
Yesterday: [What was completed]
Today: [What will be worked on]
Blockers: [Any impediments]
Help Needed: [Areas requiring assistance]
```

### 🎯 Key Milestones
- [ ] Week 1 Complete: Core integration working
- [ ] Week 2 Complete: NIP-60 fully implemented
- [ ] Week 3 Complete: NIP-61 working
- [ ] Week 4 Complete: UI functional
- [ ] Week 5 Complete: Production ready

### 🔄 Post-Launch
- [ ] Monitor crash reports
- [ ] Track wallet usage metrics
- [ ] Gather user feedback
- [ ] Plan v2 features

---

**Remember**: Check off items as completed. Update blocker log daily. This is your single source of truth for implementation progress.