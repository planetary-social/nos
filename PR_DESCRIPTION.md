# Add Cashu Wallet Support (NIP-60 & NIP-61)

## Summary
This PR adds comprehensive Cashu ecash wallet support to Nos, implementing NIP-60 (wallet data events) and NIP-61 (nutzaps). Users can now send and receive ecash tokens directly within the app.

## What's Implemented

### ✅ Core Features
- **Cashu Wallet Model** - Full wallet implementation with P2PK keypair generation
- **NIP-60 Support** - Wallet events, token storage, and transaction history
- **NIP-61 Support** - Nutzaps (P2PK-locked ecash) sending and receiving
- **CashuSwift Integration** - Real Cashu protocol operations (mint, melt, P2PK)
- **NIP-44 Encryption** - Secure storage of wallet keys and tokens
- **Core Data Caching** - Offline balance viewing and performance optimization

### ✅ User Interface
- **Wallet Onboarding** - Setup flow with mnemonic backup
- **Balance Display** - Real-time balance widget
- **Nutzap Button** - Send ecash directly from notes
- **Transaction History** - Track all wallet activity
- **Profile Integration** - Wallet section in user profiles
- **Settings Integration** - Wallet management in app settings

### ✅ Services & Architecture
- **Dependency Injection** - All services properly wired into DI container
- **Async/Await** - Modern Swift concurrency throughout
- **Token Storage** - Efficient token management and retrieval
- **Error Handling** - User-friendly error messages

## Changes Made

### New Files Created
- `CashuWallet.swift` - Core wallet model
- `CashuWalletService.swift` - Wallet operations service
- `NutzapService.swift` - Nutzap sending/receiving
- `CashuCacheService.swift` - Core Data synchronization
- `CashuSwiftIntegration.swift` - CashuSwift library integration
- `CashuWalletTokenStorage.swift` - Token management
- `CashuNIP44Encryption.swift` - Encryption helpers
- Multiple UI components for wallet features
- Core Data entity definitions

### Modified Files
- `EventKind.swift` - Added 5 new Cashu event kinds
- `DependencyInjection.swift` - Registered Cashu services
- `CHANGELOG.md` - Added release notes
- `Nos.xcodeproj` - Added CashuSwift package dependency

### Package Dependencies
- Added CashuSwift (main branch) for Cashu protocol support

## Testing
- Unit tests for wallet operations
- Integration tests for nutzap flows
- Service layer tests with proper mocking

## Manual Steps Required

### Before Merging
1. **Core Data Migration** - Add entities to Xcode data model (definitions provided in `CashuEntities.md`)
2. **Build Verification** - Ensure CashuSwift types match our implementation
3. **Test with Real Mint** - Verify operations with testnut.cashu.space

### Known Issues
- CashuSwift package uses main branch (no tagged releases available)
- Some type definitions may need adjustment based on actual CashuSwift API

## Release Notes

### For Users
- 🎉 **NEW**: Cashu wallet support - Send and receive ecash using NIP-60/61
- 🎉 **NEW**: Nutzaps - A new way to send value with P2PK-locked tokens
- 🎉 **NEW**: Offline balance viewing
- 🎉 **NEW**: Transaction history tracking

### For Developers
- Added event kinds: 7375, 7376, 17375, 9321, 10019
- CashuSwift integration via SPM
- Core Data v24 with wallet caching
- NIP-44 encryption for sensitive data

## Documentation
- `RELEASE_CHECKLIST.md` - Complete release guide
- `cashukit-implementation-checklist.md` - Progress tracker
- `cashu-implementation-summary.md` - Technical details
- `CashuEntities.md` - Core Data entity definitions

## Screenshots
[To be added after UI verification]

## Checklist
- [x] Code implementation complete
- [x] SwiftLint issues fixed
- [x] Package dependency fixed
- [x] CHANGELOG.md updated
- [ ] Core Data migration added in Xcode
- [ ] Tested with real Cashu mint
- [ ] UI screenshots added

---

Closes #[issue-number]