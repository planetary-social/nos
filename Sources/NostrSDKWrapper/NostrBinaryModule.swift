import Foundation

// This file serves as a placeholder for the NostrSDK binary module
// In a real implementation, we would compile NostrSDK with all its dependencies
// into a binary framework (XCFramework) and include it here.
//
// For now, we're using stub implementations in other files.

#if DEBUG
public let NOSTR_BINARY_MODULE_VERSION = "1.0.0-debug"
#else
public let NOSTR_BINARY_MODULE_VERSION = "1.0.0-release"
#endif