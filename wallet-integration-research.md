# Nos Wallet Integration Research: NIP-60/61 and Cashu

## Executive Summary

This document outlines the research findings and implementation approach for adding Cashu wallet support to Nos using NIP-60 (wallet state) and NIP-61 (nutzaps).

## NIP-60: Cashu Wallet Specification

### Overview
NIP-60 defines a decentralized wallet system using Nostr relays to store wallet state, enabling cross-application interoperability.

### Key Event Types

1. **Wallet Event (kind: 17375)**
   - Stores wallet configuration and mint URLs
   - Contains encrypted private key for P2PK ecash
   - Replaceable event (one per user)

2. **Token Event (kind: 7375)**
   - Stores unspent proofs
   - Multiple events per mint supported
   - Encrypted using NIP-44
   - Deleted when spent, rolled over with change

3. **Spending History (kind: 7376)**
   - Optional transaction records
   - Tracks in/out transactions
   - References created/destroyed tokens

### Implementation Requirements
- Fetch wallet events from user's relays (fall back to NIP-65 relays)
- Handle token state transitions (spend, rollover, change)
- Encrypt all sensitive data

## NIP-61: Nutzaps Specification

### Overview
NIP-61 enables peer-to-peer Cashu token transfers via Nostr, with the payment serving as the receipt.

### Key Components

1. **Nutzap Info Event (kind: 10019)**
   - Advertises user's preferred mints
   - Contains P2PK public key for receiving
   - Specifies relay preferences

2. **Nutzap Event (kind: 9321)**
   - Contains locked Cashu tokens
   - References recipient and optional original event
   - Includes optional comment

### Flow
1. Sender fetches recipient's kind:10019
2. Mints tokens at recipient's preferred mint
3. Locks tokens to recipient's P2PK key
4. Publishes kind:9321 to recipient's relays

## Cashu Development Kit (CDK) Analysis

### Current State
- CDK is primarily a Rust implementation
- Swift bindings are planned but not yet available
- Alternative: Macadamia (existing iOS Cashu wallet in Swift)

### Options for Nos
1. **Wait for CDK Swift bindings** (timeline uncertain)
2. **Use Rust CDK via FFI** (complex but possible)
3. **Implement Cashu protocol natively in Swift** (recommended)
4. **Adapt code from Macadamia wallet** (if open source)

## Nos Integration Architecture

### Current State Analysis
- Well-structured Swift/SwiftUI app
- Existing event handling system
- Core Data for persistence
- Basic zap support (kinds 9734, 9735)
- No wallet functionality

### Integration Points

#### 1. Event System
Add to `EventKind.swift`:
```swift
case cashuWallet = 17375
case cashuToken = 7375
case cashuSpendingHistory = 7376
case nutzapInfo = 10019
case nutzap = 9321
```

#### 2. Core Data Model
New entities needed:
- `CashuWallet`: Wallet configuration
- `CashuToken`: Token storage
- `CashuMint`: Mint information
- `CashuTransaction`: Transaction history

#### 3. Service Layer
New services required:
- `CashuWalletService`: Wallet operations
- `CashuProtocolService`: Cashu protocol implementation
- `NutzapService`: Nutzap sending/receiving

#### 4. UI Components
- Wallet tab or settings section
- Balance display
- Send/receive interfaces
- Transaction history
- Mint management

## Implementation Plan

### Phase 1: Core Infrastructure (2-3 weeks)
1. Add event kinds to `EventKind.swift`
2. Create Core Data entities
3. Implement basic Cashu protocol in Swift
4. Add wallet event processing to `EventProcessor`

### Phase 2: Basic Wallet (2-3 weeks)
1. Create `CashuWalletService`
2. Implement wallet creation/recovery
3. Add balance tracking
4. Basic send/receive functionality

### Phase 3: UI Integration (1-2 weeks)
1. Add wallet section to settings
2. Create wallet management views
3. Add balance to profile
4. Transaction history view

### Phase 4: Nutzaps (1-2 weeks)
1. Implement NIP-61 event handling
2. Extend existing zap UI
3. Add nutzap notifications
4. Test interoperability

### Phase 5: Polish & Testing (1 week)
1. Error handling
2. Performance optimization
3. Security audit
4. Comprehensive testing

## Technical Considerations

### Security
- Use Keychain for wallet private keys
- Implement NIP-44 encryption properly
- Validate all proofs cryptographically
- Sanitize mint URLs

### Performance
- Cache token states locally
- Batch relay operations
- Optimize Core Data queries
- Consider background processing

### UX Considerations
- Simple onboarding flow
- Clear balance display
- Intuitive send/receive
- Transaction status feedback

## Risks & Mitigations

### Risk: CDK Integration Complexity
**Mitigation**: Start with native Swift implementation, migrate to CDK when Swift bindings available

### Risk: Protocol Changes
**Mitigation**: Follow NIP specifications closely, participate in community discussions

### Risk: Mint Reliability
**Mitigation**: Support multiple mints, implement proper error handling

### Risk: User Key Management
**Mitigation**: Clear UX for backup/recovery, use existing Keychain integration

## Recommendations

1. **Start with native Swift implementation** for faster time-to-market
2. **Focus on NIP-60 first**, then add NIP-61
3. **Leverage existing Nos patterns** for consistency
4. **Consider partnering with Cashu community** for protocol guidance
5. **Plan for migration to CDK** when Swift bindings available

## Next Steps

1. Validate approach with Nos team
2. Create detailed technical design
3. Set up development branch
4. Begin Phase 1 implementation
5. Engage with Cashu/Nostr community

## Resources

- [NIP-60 Specification](https://github.com/nostr-protocol/nips/blob/master/60.md)
- [NIP-61 Specification](https://github.com/nostr-protocol/nips/blob/master/61.md)
- [Cashu Protocol](https://github.com/cashubtc/nuts)
- [CDK Repository](https://github.com/cashubtc/cdk)
- [Macadamia iOS Wallet](https://github.com/zeugmaster/macadamia)