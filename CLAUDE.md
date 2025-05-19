# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands
- Build: `xcodebuild -scheme Nos -configuration Debug`
- Run tests: `xcodebuild test -scheme NosTests -resultBundlePath TestResults`
- Run single test: `xcodebuild test -scheme NosTests -only-testing:NosTests/<TestClass>/<test_method>`
- Lint: `swiftlint`
- Check for unused code: `./Scripts/periphery.sh`

## Testing the Macadamia Integration
When working with the Macadamia wallet integration, look for the `TestCashuSwift.swift` file in the `Nos/Wallet/MacadamiaIntegration` directory. This file contains tests that verify:
- Initialization of mints (including Minibits and LNVoltz)
- Parsing of tokens (using a real Minibits token)
- Generation of BIP-39 mnemonics

The integrated UI test can be accessed in the development build by:
1. Enabling the `.useMacadamiaWallet` feature flag
2. Opening the wallet view
3. Going to the Settings tab
4. Using the "Test CashuSwift Integration" button in the Developer section

## Known Integration Issues
- There's a dependency conflict between different secp256k1 libraries
- Local package dependencies may need to be adjusted for different development environments

## Code Style Guidelines
- Follow SwiftUI/Swift conventions with 4-space indentation
- Line length max: 120 characters
- Minimum identifier length: 4 chars (except for approved exceptions)
- Use `@MainActor` for UI code
- Prefer immutable values (let over var)
- Use Swift's built-in error handling with custom error types
- Follow MVVM architecture with Core Data for persistence
- Use the native `Logger` framework for logging
- Core components follow Actor-based concurrency model
- Files should not exceed 500 lines (warning) / 1200 lines (error)