# Core Data Migration Guide for Cashu Wallet

## Overview
This guide walks through adding the Cashu wallet entities to the Core Data model in Xcode. This is a **required manual step** that cannot be done via code.

## Step 1: Create New Model Version

1. **Open Xcode** and load the Nos project
2. **Navigate to** `Nos/Models/CoreData/Nos.xcdatamodeld`
3. **Select the file** in the project navigator
4. **Create new version**:
   - Menu: Editor → Add Model Version...
   - Base model on: Nos 23 (current version)
   - Version name: `Nos 24`
   - Click "Finish"

## Step 2: Set Current Model Version

1. **Select** `Nos.xcdatamodeld` in project navigator
2. **Open File Inspector** (right panel)
3. **Under "Model Version"**, change Current to `Nos 24`
4. **Green checkmark** should move to Nos 24

## Step 3: Add CashuWalletCache Entity

1. **Select** `Nos 24.xcdatamodel`
2. **Click "Add Entity"** button at bottom
3. **Name**: `CashuWalletCache`
4. **Add Attributes** (click + in Attributes section):

| Attribute | Type | Optional | Default | Indexed |
|-----------|------|----------|---------|---------|
| id | String | NO | - | YES |
| name | String | NO | - | NO |
| primaryMintURL | String | NO | - | NO |
| trustedMints | Transformable | YES | - | NO |
| walletPublicKey | String | NO | - | NO |
| lightningAddress | String | YES | - | NO |
| lightningGateway | String | YES | - | NO |
| totalBalance | Integer 64 | NO | 0 | NO |
| lastSyncDate | Date | NO | - | NO |
| createdAt | Date | NO | - | NO |
| updatedAt | Date | NO | - | NO |

5. **Configure Transformable**:
   - Select `trustedMints` attribute
   - In Data Model Inspector:
     - Custom Class: `NSSet`
     - Transformer: `NSSecureUnarchiveFromDataTransformer`

## Step 4: Add CashuTokenCache Entity

1. **Click "Add Entity"**
2. **Name**: `CashuTokenCache`
3. **Add Attributes**:

| Attribute | Type | Optional | Default | Indexed |
|-----------|------|----------|---------|---------|
| id | String | NO | - | YES |
| mintURL | String | NO | - | NO |
| amount | Integer 64 | NO | - | NO |
| tokenData | Binary | NO | - | NO |
| isSpent | Boolean | NO | NO | NO |
| spentAt | Date | YES | - | NO |
| createdAt | Date | NO | - | NO |
| updatedAt | Date | NO | - | NO |

4. **Configure Binary**:
   - Select `tokenData` attribute
   - Check "Allows External Storage"

## Step 5: Add CashuTransaction Entity

1. **Click "Add Entity"**
2. **Name**: `CashuTransaction`
3. **Add Attributes**:

| Attribute | Type | Optional | Default | Indexed |
|-----------|------|----------|---------|---------|
| id | String | NO | - | YES |
| type | String | NO | - | NO |
| amount | Integer 64 | NO | - | NO |
| mintURL | String | NO | - | NO |
| lightningInvoice | String | YES | - | NO |
| recipientPubkey | String | YES | - | NO |
| comment | String | YES | - | NO |
| status | String | NO | "pending" | NO |
| createdAt | Date | NO | - | NO |
| completedAt | Date | YES | - | NO |

## Step 6: Add Relationships

### CashuWalletCache Relationships:
1. **Select** `CashuWalletCache` entity
2. **Add Relationships** (click + in Relationships section):

| Relationship | Destination | Inverse | Type | Delete Rule | Optional |
|--------------|-------------|---------|------|-------------|----------|
| author | Author | cashuWallets | To One | Nullify | NO |
| tokens | CashuTokenCache | wallet | To Many | Cascade | YES |
| transactions | CashuTransaction | wallet | To Many | Cascade | YES |
| walletEvent | Event | cashuWallet | To One | Nullify | YES |

### CashuTokenCache Relationships:

| Relationship | Destination | Inverse | Type | Delete Rule | Optional |
|--------------|-------------|---------|------|-------------|----------|
| wallet | CashuWalletCache | tokens | To One | Nullify | NO |
| tokenEvent | Event | cashuTokens | To One | Nullify | YES |
| transaction | CashuTransaction | tokens | To One | Nullify | YES |

### CashuTransaction Relationships:

| Relationship | Destination | Inverse | Type | Delete Rule | Optional |
|--------------|-------------|---------|------|-------------|----------|
| wallet | CashuWalletCache | transactions | To One | Nullify | NO |
| tokens | CashuTokenCache | transaction | To Many | Nullify | YES |
| nutzapEvent | Event | cashuTransaction | To One | Nullify | YES |

## Step 7: Update Existing Entities

### Update Author Entity:
1. **Select** `Author` entity
2. **Add Relationship**:
   - Name: `cashuWallets`
   - Destination: `CashuWalletCache`
   - Type: To Many
   - Delete Rule: Cascade
   - Inverse: `author`

### Update Event Entity:
1. **Select** `Event` entity
2. **Add Relationships**:

| Relationship | Destination | Inverse | Type | Delete Rule |
|--------------|-------------|---------|------|-------------|
| cashuWallet | CashuWalletCache | walletEvent | To One | Nullify |
| cashuTokens | CashuTokenCache | tokenEvent | To Many | Nullify |
| cashuTransaction | CashuTransaction | nutzapEvent | To One | Nullify |

## Step 8: Generate NSManagedObject Subclasses

1. **Select all three new entities** (Cmd+click each)
2. **Menu**: Editor → Create NSManagedObject Subclass...
3. **Select** `Nos 24` data model
4. **Select** all three Cashu entities
5. **Choose**:
   - Language: Swift
   - Module: Current Product Module
   - Codegen: Manual/None
6. **Save to**: `Nos/Models/CoreData/`
7. **Delete generated files** (we already created custom ones)

## Step 9: Build and Test

1. **Build the project** (Cmd+B)
2. **Check for errors** related to Core Data
3. **Run on simulator** to test migration
4. **Verify** no crashes on app launch

## Troubleshooting

### If app crashes on launch:
1. Delete app from simulator/device
2. Clean build folder (Shift+Cmd+K)
3. Rebuild and run

### If relationships don't work:
1. Double-check inverse relationships
2. Ensure delete rules are correct
3. Verify optional settings match code

### If migration fails:
1. Check PersistenceController.swift for migration settings
2. Ensure lightweight migration is enabled
3. Consider adding mapping model if needed

## Verification

After completing migration:
1. **Create a test wallet** in the app
2. **Check Core Data browser** to see entities
3. **Verify relationships** are properly connected
4. **Test CRUD operations** on wallet data

## Important Notes

- **DO NOT** skip this step - the app will crash without these entities
- **DO NOT** modify Nos 23 model - always create new version
- **DO** test on a clean install after migration
- **DO** backup any test data before migration

This completes the Core Data migration setup!