# Binary Implementation Plan for Macadamia Wallet

This document outlines the plan for creating a binary implementation of the Macadamia wallet integration to resolve dependency conflicts.

## Overview

To avoid conflicts between secp256k1 libraries, we'll create a binary framework (XCFramework) that encapsulates all the functionality needed from NostrSDK and CashuSwift.

## Implementation Steps

1. **Create a Separate Repository**:
   - Set up a new repository for building the binary framework
   - Include the necessary dependencies:
     - NostrSDK
     - CashuSwift
     - Any other required libraries

2. **Create a Wrapper API**:
   - Design a clean API that abstracts the underlying dependencies
   - Expose only what's needed by the Nos app
   - Include all necessary functionality for wallet operations

3. **Build the XCFramework**:
   - Use xcodebuild to create the binary framework
   - Include all necessary architectures (arm64, x86_64)
   - Create a versioning scheme

4. **Integration into Nos**:
   - Add the XCFramework to the Nos project
   - Update the code to use the binary framework
   - Remove direct dependencies on conflicting packages

## API Design

The binary framework should expose the following components:

```swift
// Main wallet functionality
public class MacadamiaWalletBridge {
    // Wallet setup
    func createWallet() async throws
    func restoreWallet(mnemonic: String) async throws
    
    // Wallet operations
    func addMint(url: URL) async throws
    func send(amount: Int, to: String, mint: MintModel) async throws -> String
    func receive(token: String) async throws
    func mint(amount: Int, mint: MintModel) async throws
    func melt(invoice: String, mint: MintModel) async throws
    
    // Property access
    var balance: Int { get }
    var mints: [MintModel] { get }
    var transactions: [TransactionModel] { get }
}

// Nostr event handling
public class NostrEventHandler {
    func handleEvent(event: [String: Any]) async throws -> [String: Any]?
}

// Wallet launcher
public class MacadamiaLauncher {
    static func launch() -> Bool
    static func isInstalled() -> Bool
    static func openWebWallet() -> Bool
}
```

## Data Models

The binary framework should also include all necessary data models:

```swift
public struct WalletModel: Identifiable, Equatable, Codable {
    let id: UUID
    let seed: String
    let mnemonic: String
    let createdAt: Date
    var name: String?
}

public struct MintModel: Identifiable, Equatable, Codable {
    let id: UUID
    let url: URL
    let name: String
    let addedAt: Date
    var keysets: [KeysetModel]
    var balance: Int
    var isActive: Bool
}

public struct ProofModel: Identifiable, Equatable, Codable {
    let id: UUID
    let keysetId: String
    let C: String
    let secret: String
    let amount: Int
    let mintURL: URL
    var state: State
    
    enum State: String, Codable, Comparable {
        case valid
        case pending
        case spent
    }
}

public struct TransactionModel: Identifiable, Codable {
    let id: UUID
    let type: TransactionType
    let amount: Int
    let timestamp: Date
    let memo: String?
    var status: TransactionStatus
    var tokenData: String?
    
    enum TransactionType: String, Identifiable, CaseIterable, Codable {
        case mint
        case melt
        case send
        case receive
    }
    
    enum TransactionStatus: String, Codable {
        case pending
        case completed
        case failed
    }
}
```

## Build Script

Create a build script to automate the XCFramework creation:

```bash
#!/bin/bash

# Set variables
FRAMEWORK_NAME="MacadamiaWallet"
OUTPUT_DIR="./build"
SCHEME_NAME="MacadamiaWallet"

# Clean previous builds
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# Build for iOS
xcodebuild archive \
  -scheme "$SCHEME_NAME" \
  -destination "generic/platform=iOS" \
  -archivePath "$OUTPUT_DIR/iOS.xcarchive" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES

# Build for iOS Simulator
xcodebuild archive \
  -scheme "$SCHEME_NAME" \
  -destination "generic/platform=iOS Simulator" \
  -archivePath "$OUTPUT_DIR/iOS_Simulator.xcarchive" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES

# Create XCFramework
xcodebuild -create-xcframework \
  -framework "$OUTPUT_DIR/iOS.xcarchive/Products/Library/Frameworks/$FRAMEWORK_NAME.framework" \
  -framework "$OUTPUT_DIR/iOS_Simulator.xcarchive/Products/Library/Frameworks/$FRAMEWORK_NAME.framework" \
  -output "$OUTPUT_DIR/$FRAMEWORK_NAME.xcframework"

echo "Created $FRAMEWORK_NAME.xcframework in $OUTPUT_DIR"
```

## Integration Testing

To test the integration:

1. Build the XCFramework
2. Add it to the Nos project
3. Update the code to use the binary framework
4. Test all wallet operations
5. Verify NIP-60 and NIP-61 support

## Versioning and Updates

Establish a versioning scheme for the XCFramework:
- Major version: Breaking API changes
- Minor version: Non-breaking feature additions
- Patch version: Bug fixes and small improvements

Document the update process for future maintainers.