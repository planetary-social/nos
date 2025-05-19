#!/usr/bin/swift

import Foundation

// Check if CashuSwift is available
print("Testing CashuSwift integration...")

// Import statements - these will fail if the dependencies aren't properly set up
// If you're getting errors here, make sure your Package.swift has the proper dependencies
print("Importing dependencies...")
import cashu_swift
import BIP39

// Function to test token parsing
func testTokenParsing() async {
    print("\n== Testing Token Parsing ==")
    
    // Real Minibits token
    let minibitsToken = "fed11qvqpw9thwden5te0v9sjuctnvcczummjvuhhwue0qqqpj9mhwden5te0vekkwvfwv3cxcetz9e5kutmhwvhszqfqax36q0annypfxsxqarfecykxk7tk3ynwq2yxphr8qx46hr9cvn0qmctpcm"
    
    do {
        let token = try CashuSwift.parseToken(minibitsToken)
        print("✅ Successfully parsed Minibits token")
        print("Token mints: \(token.tokens.keys.joined(separator: ", "))")
        
        // Show proof details if available
        for (mint, mintData) in token.tokens {
            print("Mint: \(mint)")
            print("Proofs count: \(mintData.proofs.count)")
            
            var totalAmount = 0
            for (index, proof) in mintData.proofs.enumerated() {
                totalAmount += proof.amount
                print("  Proof #\(index + 1):")
                print("    Amount: \(proof.amount) sats")
                print("    ID: \(proof.id)")
            }
            print("  Total token value: \(totalAmount) sats")
        }
    } catch {
        print("❌ Failed to parse token: \(error)")
    }
}

// Function to test mint initialization
func testMintInitialization() async {
    print("\n== Testing Mint Initialization ==")
    
    // Test Minibits mint
    let minibitsURL = URL(string: "https://mint.minibits.cash/Bitcoin")!
    do {
        print("Testing Minibits mint...")
        let mint = try await CashuSwift.Mint(with: minibitsURL)
        print("✅ Successfully initialized Minibits mint")
        print("Keysets count: \(mint.keysets.count)")
        
        if !mint.keysets.isEmpty {
            let firstKeyset = mint.keysets.first!
            print("First keyset ID: \(firstKeyset.keysetID)")
        }
    } catch {
        print("❌ Failed to initialize Minibits mint: \(error)")
    }
    
    // Test LNVoltz mint
    let lnvoltzURL = URL(string: "https://mint.lnvoltz.com")!
    do {
        print("\nTesting LNVoltz mint...")
        let mint = try await CashuSwift.Mint(with: lnvoltzURL)
        print("✅ Successfully initialized LNVoltz mint")
        print("Keysets count: \(mint.keysets.count)")
        
        if !mint.keysets.isEmpty {
            let firstKeyset = mint.keysets.first!
            print("First keyset ID: \(firstKeyset.keysetID)")
        }
    } catch {
        print("❌ Failed to initialize LNVoltz mint: \(error)")
    }
}

// Function to test mnemonic generation
func testMnemonicGeneration() {
    print("\n== Testing BIP39 Mnemonic Generation ==")
    
    do {
        guard let entropy = BIP39.Entropy(bitLength: 128) else {
            print("❌ Failed to generate entropy")
            return
        }
        
        let mnemonic = BIP39.Mnemonic(entropy: entropy)
        let words = mnemonic.words
        
        print("✅ Successfully generated mnemonic with \(words.count) words")
        print("First few words: \(words.prefix(3).joined(separator: " "))")
        
        // Validate the mnemonic
        let isValid = BIP39.Mnemonic.isValid(words: words)
        print("Mnemonic is valid: \(isValid)")
    } catch {
        print("❌ Failed to generate mnemonic: \(error)")
    }
}

// Run all tests
async {
    print("Starting CashuSwift integration tests...")
    await testTokenParsing()
    await testMintInitialization()
    testMnemonicGeneration()
    print("\nTests completed!")
}

// Wait for async operations to complete
dispatchMain()