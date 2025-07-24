# Core Data Entities for Cashu Wallet

## Overview
While the current implementation uses Nostr events (NIP-60/61) for wallet data persistence, adding dedicated Core Data entities will provide:
- Better query performance for local wallet operations
- Offline caching of wallet state
- Efficient balance calculations
- Transaction history tracking

## Proposed Entities

### 1. CashuWalletCache
Local cache of wallet data synchronized with Nostr events.

**Attributes:**
- `id`: String (UUID)
- `name`: String
- `primaryMintURL`: String
- `trustedMints`: Transformable (Set<String>)
- `walletPublicKey`: String
- `lightningAddress`: String?
- `lightningGateway`: String?
- `totalBalance`: Int64 (cached sum)
- `lastSyncDate`: Date
- `createdAt`: Date
- `updatedAt`: Date

**Relationships:**
- `author`: To-one relationship with Author
- `tokens`: To-many relationship with CashuTokenCache
- `transactions`: To-many relationship with CashuTransaction
- `walletEvent`: To-one relationship with Event (NIP-60 wallet event)

### 2. CashuTokenCache
Local cache of tokens synchronized with token events.

**Attributes:**
- `id`: String (UUID)
- `mintURL`: String
- `amount`: Int64
- `tokenData`: Binary (encrypted token data)
- `isSpent`: Boolean
- `spentAt`: Date?
- `createdAt`: Date
- `updatedAt`: Date

**Relationships:**
- `wallet`: To-one relationship with CashuWalletCache
- `tokenEvent`: To-one relationship with Event (NIP-60 token event)
- `transaction`: To-one relationship with CashuTransaction (if spent)

### 3. CashuTransaction
Track all wallet transactions for history and analytics.

**Attributes:**
- `id`: String (UUID)
- `type`: String (mint, melt, send, receive)
- `amount`: Int64
- `mintURL`: String
- `lightningInvoice`: String?
- `recipientPubkey`: String?
- `comment`: String?
- `status`: String (pending, completed, failed)
- `createdAt`: Date
- `completedAt`: Date?

**Relationships:**
- `wallet`: To-one relationship with CashuWalletCache
- `tokens`: To-many relationship with CashuTokenCache
- `nutzapEvent`: To-one relationship with Event (for nutzaps)

### 4. CashuMintInfo (Optional)
Cache mint information for offline access.

**Attributes:**
- `url`: String (primary key)
- `name`: String?
- `pubkey`: String?
- `isActive`: Boolean
- `lastHealthCheck`: Date
- `supportedNuts`: Transformable (Set<Int>)

**Relationships:**
- `wallets`: To-many relationship with CashuWalletCache
- `tokens`: To-many relationship with CashuTokenCache

## Migration Strategy

1. **Version 24 Model**: Create new version with Cashu entities
2. **Lightweight Migration**: Core Data should handle this automatically
3. **Data Population**: On first launch after update:
   - Parse existing wallet events to populate CashuWalletCache
   - Parse token events to populate CashuTokenCache
   - Build transaction history from events

## Sync Strategy

1. **Event-Driven Updates**: When Nostr events are received/created:
   - Update corresponding cache entities
   - Maintain bidirectional sync

2. **Periodic Sync**: Background task to:
   - Validate cache consistency
   - Update balance calculations
   - Clean up spent tokens

3. **Conflict Resolution**: Nostr events are source of truth
   - Cache is rebuilt from events if inconsistencies detected

## Implementation Steps

1. Create new Core Data model version
2. Add entities with attributes and relationships
3. Generate NSManagedObject subclasses
4. Update PersistenceController for migration
5. Implement cache population from events
6. Add sync logic to wallet and token services
7. Update UI to use cached data for performance
8. Add background sync task

## Benefits

1. **Performance**: Fast local queries without parsing events
2. **Offline Support**: Full wallet functionality when offline
3. **Analytics**: Easy transaction history and spending patterns
4. **Search**: Efficient searching of tokens and transactions
5. **Aggregations**: Quick balance calculations across mints