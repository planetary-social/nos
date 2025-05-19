# Macadamia Wallet Integration Solution

## Problem

The integration of the Macadamia wallet into Nos encountered dependency conflicts between two secp256k1 libraries:
1. `secp256k1.swift` from GigaBitcoin (used directly in our codebase)
2. `swift-secp256k1` from zeugmaster (transitive dependency through NostrSDK)

These packages both produce products with the name "secp256k1", which causes Swift Package Manager to fail with the error:
```
multiple packages declare products with a conflicting name: 'secp256k1'; product names need to be unique across the package graph
```

## Solution

We've implemented a workaround with the following components:

1. **NostrSDKWrapper** - A package providing all the functionality needed without direct dependencies on conflicting libraries:
   - `NostrEvent.swift` - Implementation of Nostr event structure
   - `NostrSDKUtils.swift` - Utility functions for Nostr
   - `CashuSupport.swift` - Implementation of Cashu wallet functionality
   - `NostrBinaryModule.swift` - Placeholder for binary module

2. **CashuSwiftWrapper** - A bridge between our code and the Cashu functionality:
   - Provides methods that mirror the CashuSwift API
   - Implemented with local-only code to avoid dependencies
   - Can parse and verify the test token:
     ```
     fed11qvqpw9thwden5te0v9sjuctnvcczummjvuhhwue0qqqpj9mhwden5te0vekkwvfwv3cxcetz9e5kutmhwvhszqfqax36q0annypfxsxqarfecykxk7tk3ynwq2yxphr8qx46hr9cvn0qmctpcm
     ```

3. **MacadamiaWalletBridge** - The main class implementing wallet functionality:
   - Uses our CashuSwiftWrapper instead of direct dependencies
   - Implements all wallet operations: create, restore, send, receive, mint, melt
   - Supports the required mints: Minibits and LNVoltz

4. **MacadamiaLauncher** - A platform-independent launcher for the Macadamia wallet:
   - Works on iOS with custom URL scheme
   - Falls back to web wallet when needed
   - Easy to integrate into NosWalletManager

5. **Feature Flag Control** - The wallet integration is controlled via feature flags:
   - `useMacadamiaWallet` - Enables the Macadamia wallet integration

## Next Steps

To fully resolve the dependency conflicts, the next steps would be:

1. **Binary Framework Approach**:
   - Create XCFrameworks for NostrSDK and CashuSwift
   - Include these as binary dependencies (avoiding SPM conflicts)
   - Update the wrapper implementations to use these binaries

2. **Fork Dependencies**:
   - Create forks of the conflicting libraries with renamed products
   - Update dependencies to use these forks
   - This requires less maintenance than binary frameworks

3. **Xcode Project Configuration**:
   - Modify the Xcode project to directly include the Macadamia wallet code
   - Bypass Swift Package Manager entirely for these components
   - This is the most direct but least maintainable approach

## Testing

The current implementation can be tested by:

1. Setting the feature flag `useMacadamiaWallet` to true
2. Receiving the test token:
   ```
   fed11qvqpw9thwden5te0v9sjuctnvcczummjvuhhwue0qqqpj9mhwden5te0vekkwvfwv3cxcetz9e5kutmhwvhszqfqax36q0annypfxsxqarfecykxk7tk3ynwq2yxphr8qx46hr9cvn0qmctpcm
   ```
3. Testing wallet operations with the default mints:
   - https://legend.lnbits.com/cashu/api/v1/4gr9Xcmz3XEkUNwiBiQGoL
   - https://mint.bbqcashu.com
   - https://mint.minibits.cash/Bitcoin (Minibits)
   - https://mint.lnvoltz.com (LNVoltz)

4. Using the launcher to open the Macadamia wallet