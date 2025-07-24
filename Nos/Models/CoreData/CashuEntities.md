# Cashu Core Data Entities Definition

## Instructions for Adding to Xcode

1. Open `Nos.xcdatamodeld` in Xcode
2. Create a new model version (Nos 24)
3. Add the following entities with their attributes and relationships

## Entity: CashuWalletCache

### Attributes:
- **id** (String, Non-optional)
  - Indexed: Yes
  - Used as unique identifier
  
- **name** (String, Non-optional)
  
- **primaryMintURL** (String, Non-optional)
  
- **trustedMints** (Transformable, Optional)
  - Custom Class: NSSet
  - Transformer: NSSecureUnarchiveFromDataTransformer
  
- **walletPublicKey** (String, Non-optional)
  
- **lightningAddress** (String, Optional)
  
- **lightningGateway** (String, Optional)
  
- **totalBalance** (Integer 64, Non-optional)
  - Default Value: 0
  
- **lastSyncDate** (Date, Non-optional)
  
- **createdAt** (Date, Non-optional)
  
- **updatedAt** (Date, Non-optional)

### Relationships:
- **author** (To One)
  - Destination: Author
  - Inverse: cashuWallets
  - Delete Rule: Nullify
  - Optional: No
  
- **tokens** (To Many)
  - Destination: CashuTokenCache
  - Inverse: wallet
  - Delete Rule: Cascade
  - Optional: Yes
  
- **transactions** (To Many)
  - Destination: CashuTransaction
  - Inverse: wallet
  - Delete Rule: Cascade
  - Optional: Yes
  
- **walletEvent** (To One)
  - Destination: Event
  - Inverse: cashuWallet
  - Delete Rule: Nullify
  - Optional: Yes

## Entity: CashuTokenCache

### Attributes:
- **id** (String, Non-optional)
  - Indexed: Yes
  
- **mintURL** (String, Non-optional)
  
- **amount** (Integer 64, Non-optional)
  
- **tokenData** (Binary, Non-optional)
  - Allows External Storage: Yes
  
- **isSpent** (Boolean, Non-optional)
  - Default Value: NO
  
- **spentAt** (Date, Optional)
  
- **createdAt** (Date, Non-optional)
  
- **updatedAt** (Date, Non-optional)

### Relationships:
- **wallet** (To One)
  - Destination: CashuWalletCache
  - Inverse: tokens
  - Delete Rule: Nullify
  - Optional: No
  
- **tokenEvent** (To One)
  - Destination: Event
  - Inverse: cashuTokens
  - Delete Rule: Nullify
  - Optional: Yes
  
- **transaction** (To One)
  - Destination: CashuTransaction
  - Inverse: tokens
  - Delete Rule: Nullify
  - Optional: Yes

## Entity: CashuTransaction

### Attributes:
- **id** (String, Non-optional)
  - Indexed: Yes
  
- **type** (String, Non-optional)
  - Possible values: "mint", "melt", "send", "receive"
  
- **amount** (Integer 64, Non-optional)
  
- **mintURL** (String, Non-optional)
  
- **lightningInvoice** (String, Optional)
  
- **recipientPubkey** (String, Optional)
  
- **comment** (String, Optional)
  
- **status** (String, Non-optional)
  - Default Value: "pending"
  - Possible values: "pending", "completed", "failed"
  
- **createdAt** (Date, Non-optional)
  
- **completedAt** (Date, Optional)

### Relationships:
- **wallet** (To One)
  - Destination: CashuWalletCache
  - Inverse: transactions
  - Delete Rule: Nullify
  - Optional: No
  
- **tokens** (To Many)
  - Destination: CashuTokenCache
  - Inverse: transaction
  - Delete Rule: Nullify
  - Optional: Yes
  
- **nutzapEvent** (To One)
  - Destination: Event
  - Inverse: cashuTransaction
  - Delete Rule: Nullify
  - Optional: Yes

## Updates to Existing Entities

### Event Entity
Add the following relationships:
- **cashuWallet** (To One)
  - Destination: CashuWalletCache
  - Inverse: walletEvent
  - Delete Rule: Nullify
  - Optional: Yes
  
- **cashuTokens** (To Many)
  - Destination: CashuTokenCache
  - Inverse: tokenEvent
  - Delete Rule: Nullify
  - Optional: Yes
  
- **cashuTransaction** (To One)
  - Destination: CashuTransaction
  - Inverse: nutzapEvent
  - Delete Rule: Nullify
  - Optional: Yes

### Author Entity
Add the following relationship:
- **cashuWallets** (To Many)
  - Destination: CashuWalletCache
  - Inverse: author
  - Delete Rule: Cascade
  - Optional: Yes

## NSManagedObject Subclass Settings

For each entity, generate NSManagedObject subclasses with:
- Module: Current Product Module
- Codegen: Manual/None (to allow custom implementations)
- Create separate files for each entity