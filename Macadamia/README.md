# Macadamia Wallet Integration for Nos

This directory contains files for integrating the Macadamia wallet with the Nos app.

## Overview

The Macadamia wallet integration provides Bitcoin Ecash functionality within Nos using the Cashu protocol. It supports:

- Creating and restoring wallets using BIP39 mnemonics
- Sending and receiving tokens
- Minting new tokens via Lightning Network
- Paying Lightning invoices
- Support for multiple mints including Minibits and LNVoltz
- NIP-60 and NIP-61 support for wallet interactions

## Current Implementation

Due to dependency conflicts with secp256k1 libraries, we've implemented a wrapper approach:

1. `NostrSDKWrapper` - A package that provides all necessary functionality without directly importing conflicting dependencies
2. `CashuSwiftWrapper` - A bridge between our code and Cashu functionality
3. `MacadamiaWalletBridge` - The main implementation of wallet functionality
4. `MacadamiaLauncher` - A platform-independent launcher for the standalone wallet

## Default Mints

The integration supports these default mints:
- https://legend.lnbits.com/cashu/api/v1/4gr9Xcmz3XEkUNwiBiQGoL
- https://mint.bbqcashu.com
- https://mint.minibits.cash/Bitcoin (Minibits)
- https://mint.lnvoltz.com (LNVoltz)

## Documentation

- [INTEGRATION.md](./INTEGRATION.md) - Detailed explanation of the integration solution
- [BinaryImplementationPlan.md](./BinaryImplementationPlan.md) - Future plan for binary framework approach

## Feature Flags

The wallet integration can be controlled through feature flags in `FeatureFlags.swift`:
- `useMacadamiaWallet` - When true, uses the Macadamia wallet integration

## Testing

To test the integration:

1. Ensure the `useMacadamiaWallet` feature flag is set to true
2. Receive the test token:
   ```
   fed11qvqpw9thwden5te0v9sjuctnvcczummjvuhhwue0qqqpj9mhwden5te0vekkwvfwv3cxcetz9e5kutmhwvhszqfqax36q0annypfxsxqarfecykxk7tk3ynwq2yxphr8qx46hr9cvn0qmctpcm
   ```
3. Test all wallet operations with the default mints

## Next Steps

The next step is to implement a binary framework approach as described in the [Binary Implementation Plan](./BinaryImplementationPlan.md) to fully resolve the dependency conflicts.