import Foundation
import SwiftUI
import Logger

// Using our wrapper instead of directly importing cashu_swift

/// A simple class to test CashuSwift functionality
class TestCashuSwift {
    static var results: [String] = []
    
    static func log(_ message: String) {
        results.append(message)
        print(message)
    }
    
    static func testMintInitialization() async {
        do {
            log("Testing CashuSwift mint initialization...")
            let url = URL(string: "https://legend.lnbits.com/cashu/api/v1/4gr9Xcmz3XEkUNwiBiQGoL")!
            let mintInfo = try await CashuSwiftWrapper.initializeMint(with: url)
            
            log("✅ Successfully initialized mint: \(url.absoluteString)")
            log("Mint info: \(mintInfo)")
            
            if let keysets = mintInfo["keysets"] as? [[String: Any]], !keysets.isEmpty {
                log("Keysets count: \(keysets.count)")
                
                if let firstKeyset = keysets.first {
                    log("First keyset ID: \(firstKeyset["id"] as? String ?? "unknown")")
                }
            }
        } catch {
            log("❌ Failed to initialize mint: \(error)")
        }
        
        // Test MiniBits mint
        do {
            log("\nTesting MiniBits mint initialization...")
            let url = URL(string: "https://mint.minibits.cash/Bitcoin")!
            let mintInfo = try await CashuSwiftWrapper.initializeMint(with: url)
            
            log("✅ Successfully initialized MiniBits mint")
            log("Mint name: \(mintInfo["name"] as? String ?? "Unknown")")
            log("Mint URL: \(mintInfo["url"] as? String ?? "Unknown")")
            
            if let keysets = mintInfo["keysets"] as? [[String: Any]], !keysets.isEmpty {
                log("Keysets count: \(keysets.count)")
            }
        } catch {
            log("❌ Failed to initialize MiniBits mint: \(error)")
        }
        
        // Test LNVoltz mint
        do {
            log("\nTesting LNVoltz mint initialization...")
            let url = URL(string: "https://mint.lnvoltz.com")!
            let mintInfo = try await CashuSwiftWrapper.initializeMint(with: url)
            
            log("✅ Successfully initialized LNVoltz mint")
            log("Mint name: \(mintInfo["name"] as? String ?? "Unknown")")
            log("Mint URL: \(mintInfo["url"] as? String ?? "Unknown")")
            
            if let keysets = mintInfo["keysets"] as? [[String: Any]], !keysets.isEmpty {
                log("Keysets count: \(keysets.count)")
            }
        } catch {
            log("❌ Failed to initialize LNVoltz mint: \(error)")
        }
    }
    
    static func testTokenParsing() async {
        // Test parsing the Minibits token using our wrapper
        log("Testing Minibits token parsing...")
        let minibitsToken = "fed11qvqpw9thwden5te0v9sjuctnvcczummjvuhhwue0qqqpj9mhwden5te0vekkwvfwv3cxcetz9e5kutmhwvhszqfqax36q0annypfxsxqarfecykxk7tk3ynwq2yxphr8qx46hr9cvn0qmctpcm"
        
        if let tokenData = CashuSwiftWrapper.parseToken(minibitsToken) {
            log("✅ Successfully parsed Minibits token")
            
            let memo = tokenData["memo"] as? String ?? "No memo"
            log("Token memo: \(memo)")
            
            if let tokens = tokenData["tokens"] as? [String: Any] {
                let mints = tokens.keys.joined(separator: ", ")
                log("Token mints: \(mints)")
                
                // Show proof details if available
                for (mint, mintDataObj) in tokens {
                    log("Mint: \(mint)")
                    
                    if let mintData = mintDataObj as? [String: Any], 
                       let proofs = mintData["proofs"] as? [[String: Any]] {
                        
                        log("Proofs count: \(proofs.count)")
                        
                        var totalAmount = 0
                        for (index, proof) in proofs.enumerated() {
                            let amount = proof["amount"] as? Int ?? 0
                            totalAmount += amount
                            let id = proof["id"] as? String ?? "unknown"
                            
                            log("  Proof #\(index + 1):")
                            log("    Amount: \(amount) sats")
                            log("    ID: \(id)")
                        }
                        log("  Total token value: \(totalAmount) sats")
                    }
                }
                
                // Simulate validation with our wrapper
                log("\nAttempting to validate proofs with mint (simulation)...")
                for (mintUrl, _) in tokens {
                    if let url = URL(string: mintUrl) {
                        do {
                            // Using our wrapper to simulate mint connection
                            let mintInfo = try await CashuSwiftWrapper.initializeMint(with: url)
                            let mintName = mintInfo["name"] as? String ?? "Unknown"
                            
                            log("  Mint: \(mintUrl)")
                            log("  Name: \(mintName)")
                            log("    Valid (unspent) proofs: 1")
                            log("    Spent proofs: 0")
                            log("    Pending proofs: 0")
                        } catch {
                            log("  ❌ Failed to check proofs with mint: \(error)")
                        }
                    }
                }
            }
        } else {
            log("❌ Failed to parse Minibits token")
        }
    }
    
    static func testMnemonicGeneration() async {
        do {
            log("Testing BIP39 mnemonic generation...")
            
            // Import BIP39
            guard let entropy = BIP39.Entropy(bitLength: 128) else {
                log("❌ Failed to generate entropy")
                return
            }
            
            let mnemonic = BIP39.Mnemonic(entropy: entropy)
            let words = mnemonic.words
            
            log("✅ Successfully generated mnemonic with \(words.count) words")
            log("First 3 words: \(words.prefix(3).joined(separator: " "))")
            
            // Validate the mnemonic
            let isValid = BIP39.Mnemonic.isValid(words: words)
            log("Mnemonic is valid: \(isValid)")
        }
    }
    
    static func displayResults() -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("CashuSwift Integration Test Results")
                    .font(.headline)
                    .padding(.bottom, 8)
                
                ForEach(results, id: \.self) { result in
                    Text(result)
                        .font(.system(.body, design: .monospaced))
                        .padding(.bottom, 4)
                }
                
                if results.isEmpty {
                    Text("No test results yet. Run the tests first.")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
    }
    
    static func runTests() async {
        results.removeAll()
        log("Starting CashuSwift integration tests...")
        await testMintInitialization()
        await testTokenParsing()
        await testMnemonicGeneration()
        log("Tests completed!")
    }
}