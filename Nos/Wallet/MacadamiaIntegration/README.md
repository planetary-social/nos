# Macadamia Wallet Integration

This directory contains the integration between Nos and the Macadamia wallet implementation, which is based on the CashuSwift library. This integration allows Nos users to use the Cashu protocol for Bitcoin Ecash directly within the app.

## Components

- **MacadamiaWalletBridge**: The core component that connects Nos to the CashuSwift library. It handles wallet creation, restoration, sending, receiving, and other operations.
- **TestCashuSwift**: A utility for testing the CashuSwift integration, providing simple tests for mints, tokens, and mnemonics.

## Default Mints

The integration includes support for the following default mints:

1. Legend LNBits: `https://legend.lnbits.com/cashu/api/v1/4gr9Xcmz3XEkUNwiBiQGoL`
2. BBQ Cashu: `https://mint.bbqcashu.com`
3. Minibits: `https://mint.minibits.cash/Bitcoin`
4. LNVoltz: `https://mint.lnvoltz.com`

## Mint Selection

Mints are automatically added when a wallet is created or restored. Users can add additional mints through the wallet UI.

## Testing

The integration can be tested in several ways:

1. **In-App Testing**: Enable the `.useMacadamiaWallet` feature flag, navigate to the wallet settings, and use the "Test CashuSwift Integration" developer option.

2. **Unit Tests**: Run the `CashuSwiftIntegrationTests` test suite which verifies token parsing, mint initialization, and wallet creation.

3. **Command-Line Testing**: Use the `Scripts/test_cashu_integration.swift` script to run basic integration tests from the command line.

## Wallet Notes

- Wallets are backed by BIP-39 compatible 12-word mnemonics
- Mnemonic validation is implemented to ensure only valid recovery phrases are accepted
- Tokens can be received and sent between Cashu-compatible wallets

## Known Issues

- There may be dependency conflicts between different secp256k1 libraries. In some cases, you may need to modify the Package.swift file to resolve these conflicts.
- When running the integration in a development environment, local package paths may need adjustment.

## Sample Token

For testing purposes, you can use this Minibits token (note that using it in tests won't actually spend the token):

```
fed11qvqpw9thwden5te0v9sjuctnvcczummjvuhhwue0qqqpj9mhwden5te0vekkwvfwv3cxcetz9e5kutmhwvhszqfqax36q0annypfxsxqarfecykxk7tk3ynwq2yxphr8qx46hr9cvn0qmctpcm
```

## Feature Flag

The Macadamia wallet integration is controlled by the `.useMacadamiaWallet` feature flag. When enabled, the wallet button will launch the Macadamia wallet. When disabled, it will use the built-in wallet UI.