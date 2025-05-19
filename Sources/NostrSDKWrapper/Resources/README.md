# NostrSDKWrapper

This module provides a wrapper around the functionality of NostrSDK and CashuSwift without directly including them as dependencies. This approach was chosen to resolve package conflicts with secp256k1 libraries.

## Implementation Details

Instead of directly importing conflicting libraries, we implement the necessary functionality with plain Swift code that can be used by the Nos app. In a real-world scenario, we would create compiled XCFrameworks for these dependencies to avoid conflicts.

## Components

- `NostrEvent.swift` - Basic implementation of Nostr event structure
- `NostrSDKUtils.swift` - Utility functions for working with Nostr entities
- `CashuSupport.swift` - Implementation of Cashu wallet functionality
- `NostrBinaryModule.swift` - Placeholder for binary module inclusion

## Testing

Since this wrapper simulates the real implementations, it's designed to work with the same test cases. For real implementation, the actual libraries should be included as binary dependencies or compiled directly into the app.