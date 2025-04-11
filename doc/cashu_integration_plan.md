# Cashu Wallet Integration Plan for Nos

This document outlines the plan for integrating a Cashu wallet into the Nos app using the Macadamia codebase as a foundation and implementing Nostr NIP-60/61 protocols.

## 1. Overview

Cashu is a privacy-focused ecash protocol for Bitcoin, and Macadamia is an iOS wallet implementation for Cashu. Our goal is to integrate this functionality into Nos, enabling users to:

- Manage Cashu tokens directly in Nos
- Send and receive ecash payments
- Support the Nostr wallet connect protocol (NIP-60)
- Implement Cashu-specific Nostr operations (NIP-61)

## 2. Architecture

### 2.1 Modular Components

We'll organize the integration into these components:

1. **CashuCore**: Core wallet functionality ported from Macadamia
2. **NostrCashuBridge**: Implementation of NIP-60/61 protocols
3. **NosWalletUI**: User interface components
4. **WalletStateManager**: State management and persistence

### 2.2 Data Flow

```
┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│             │      │             │      │             │
│ Nos App     │<─────│ Nostr Event │<─────│ External    │
│             │      │ Handler     │      │ Applications │
│             │      │             │      │             │
└───────┬─────┘      └──────┬──────┘      └─────────────┘
        │                   │
        ▼                   ▼
┌───────────────────────────────────────┐
│                                       │
│          NostrCashuBridge             │
│                                       │
└───────────────┬───────────────────────┘
                │
                ▼
┌───────────────────────────────────────┐
│                                       │
│           CashuCore                   │
│                                       │
└───────────────┬───────────────────────┘
                │
                ▼
┌───────────────────────────────────────┐
│                                       │
│      Cashu Protocol Operations         │
│   (mint, send, receive, melt, etc.)   │
│                                       │
└───────────────────────────────────────┘
```

## 3. Implementation Steps

### 3.1 Preparation

1. **Create Module Structure**
   - Create necessary folders and Swift packages
   - Set up dependency management
   - Ensure compatibility with Nos architecture

2. **Port Core Dependencies**
   - Import CashuSwift library
   - Configure build settings
   - Resolve any compatibility issues

### 3.2 Core Functionality (from Macadamia)

1. **Wallet Management**
   - Port wallet creation/restore functionality
   - Implement seed and mnemonic handling
   - Integrate with Nos security features

2. **Mint Management**
   - Port mint discovery and connection
   - Implement keyset management
   - Add mint status monitoring

3. **Token Operations**
   - Implement token creation (minting)
   - Add token redemption (receiving)
   - Create token sending functionality
   - Add token melting (spending to LN invoice)

4. **Proof Handling**
   - Port proof validation
   - Implement proof storage
   - Add blind signature verification

5. **Event Tracking**
   - Port transaction history
   - Implement event persistence
   - Add balance calculation

### 3.3 NIP-60 Implementation (Wallet Connect)

1. **Event Handlers**
   - Implement `wallet_request` event handling
   - Create `wallet_response` event generation
   - Add request validation and security checks

2. **Connection Management**
   - Implement wallet connection protocol
   - Add permission management
   - Create connection UI flows

3. **Payment Processing**
   - Implement payment request handling
   - Create payment response generation
   - Add payment validation

### 3.4 NIP-61 Implementation (Cashu-specific)

1. **Cashu Event Types**
   - Implement `cashu_request` event handling
   - Create `cashu_response` event generation
   - Handle token sharing via Nostr

2. **Cashu Operations**
   - Implement mint discovery
   - Create proof exchange protocol
   - Add token state synchronization

3. **Lightning Integration**
   - Implement Lightning Network operations
   - Add LNURL support
   - Create Lightning invoice handling

### 3.5 UI/UX Integration

1. **Wallet UI**
   - Create main wallet view
   - Implement balance display
   - Add transaction history list
   - Create send/receive workflows

2. **QR Code Functionality**
   - Implement QR code generation
   - Add QR code scanning
   - Create shared token display

3. **Settings & Configuration**
   - Create mint management UI
   - Add wallet backup/restore options
   - Implement preferences

4. **Notifications**
   - Add transaction notifications
   - Implement balance updates
   - Create connection request alerts

### 3.6 Testing and Validation

1. **Unit Testing**
   - Test core wallet functionality
   - Validate NIP-60/61 implementations
   - Test UI components

2. **Integration Testing**
   - Test integration with Nos
   - Validate data persistence
   - Test wallet interoperability

3. **Security Audit**
   - Conduct security review
   - Validate cryptographic operations
   - Test privacy features

## 4. Key Files and Components to Port from Macadamia

### 4.1 Core Models

- `AppState.swift` - Core state management
- `PersistentModels/*.swift` - Data models for wallet, mint, proofs
- `Operations/*.swift` - Core wallet operations

### 4.2 UI Components

- `Wallet/*.swift` - Wallet view components
- `Mints/*.swift` - Mint management views
- `Misc/*.swift` - Helper UI components

### 4.3 Utility Functions

- `TokenText.swift` - Token formatting
- `QRView.swift` - QR code generation
- `QRScanner.swift` - QR code scanning

## 5. New Components to Develop

### 5.1 NIP-60/61 Protocol

- `NostrWalletConnectHandler.swift` - Main handler for NIP-60
- `NostrCashuHandler.swift` - Cashu-specific handler for NIP-61
- `WalletEventTypes.swift` - Event type definitions

### 5.2 Integration Components

- `NosWalletManager.swift` - Integration with Nos
- `NosWalletState.swift` - State management
- `NosWalletStorage.swift` - Data persistence

### 5.3 UI Extensions

- `WalletTabView.swift` - Main wallet tab
- `TransactionDetailView.swift` - Transaction details
- `NostrConnectView.swift` - Connection management

## 6. Timeline and Milestones

### Phase 1: Core Integration (2-3 weeks)
- Port essential Macadamia functionality
- Implement basic wallet operations
- Create fundamental UI components

### Phase 2: NIP-60/61 Implementation (2-3 weeks)
- Implement Nostr event handlers
- Create wallet connect protocol
- Add Cashu-specific operations

### Phase 3: UI/UX Refinement (1-2 weeks)
- Enhance user interface
- Improve user experience
- Add advanced features

### Phase 4: Testing and Deployment (1-2 weeks)
- Conduct thorough testing
- Fix bugs and issues
- Prepare for release

## 7. Challenges and Considerations

### 7.1 Security

- Ensuring secure storage of tokens and proofs
- Protecting wallet seed and private keys
- Validating transactions and connections

### 7.2 Privacy

- Maintaining user privacy
- Implementing proper blind signatures
- Ensuring token anonymity

### 7.3 Performance

- Optimizing token operations
- Ensuring responsive UI
- Managing network requests efficiently

### 7.4 Compatibility

- Ensuring compatibility with different Cashu mints
- Supporting various token versions
- Maintaining interoperability with other wallets

## 8. Resources and References

- [Macadamia GitHub Repository](https://github.com/zeugmaster/macadamia)
- [NIP-60 Specification](https://nips.nostr.com/60)
- [NIP-61 Specification](https://nips.nostr.com/61)
- [Cashu Protocol Documentation](https://cashu.space)
- [CashuSwift Library](https://github.com/cashubtc/cashu-swift)

## 9. Conclusion

This integration plan provides a comprehensive roadmap for adding Cashu wallet functionality to Nos with NIP-60/61 support. By leveraging the existing Macadamia codebase and extending it with Nostr capabilities, we can create a seamless and powerful ecash wallet experience within the Nos app.