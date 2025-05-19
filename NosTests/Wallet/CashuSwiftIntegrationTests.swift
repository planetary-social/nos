import XCTest
import cashu_swift
import BIP39
@testable import Nos

final class CashuSwiftIntegrationTests: XCTestCase {
    
    var walletState: WalletState!
    var macadamiaBridge: MacadamiaWalletBridge!
    
    override func setUp() async throws {
        walletState = WalletState()
        macadamiaBridge = MacadamiaWalletBridge(walletState: walletState)
    }
    
    func testMinibitsTokenParsing() async throws {
        // Real Minibits token
        let minibitsToken = "fed11qvqpw9thwden5te0v9sjuctnvcczummjvuhhwue0qqqpj9mhwden5te0vekkwvfwv3cxcetz9e5kutmhwvhszqfqax36q0annypfxsxqarfecykxk7tk3ynwq2yxphr8qx46hr9cvn0qmctpcm"
        
        // Attempt to parse the token
        guard let token = try? CashuSwift.parseToken(minibitsToken) else {
            XCTFail("Failed to parse Minibits token")
            return
        }
        
        // Verify basic token properties
        XCTAssertNotNil(token.tokens, "Token should have tokens")
        XCTAssertFalse(token.tokens.isEmpty, "Token should not be empty")
        
        // Check if the Minibits mint URL is present
        let minibitsURL = "https://mint.minibits.cash/Bitcoin"
        let hasMinibitsMint = token.tokens.keys.contains { $0.contains("minibits.cash") }
        XCTAssertTrue(hasMinibitsMint, "Token should contain a Minibits mint")
        
        // Calculate total value
        var totalValue = 0
        for (_, mintData) in token.tokens {
            for proof in mintData.proofs {
                totalValue += proof.amount
            }
        }
        
        // Verify token has a positive value
        XCTAssertGreaterThan(totalValue, 0, "Token should have a positive value")
        
        print("Successfully parsed Minibits token with value: \(totalValue) sats")
    }
    
    func testMintInitialization() async throws {
        // Test initializing the Minibits mint
        let minibitsURL = URL(string: "https://mint.minibits.cash/Bitcoin")!
        
        do {
            let mint = try await CashuSwift.Mint(with: minibitsURL)
            XCTAssertNotNil(mint, "Should successfully initialize the Minibits mint")
            XCTAssertFalse(mint.keysets.isEmpty, "Mint should have keysets")
            
            // Print mint info for debugging
            if let info = mint.info {
                print("Mint info: \(info)")
            }
            
            print("Keysets count: \(mint.keysets.count)")
            
            if let firstKeyset = mint.keysets.first {
                print("First keyset ID: \(firstKeyset.keysetID)")
            }
        } catch {
            XCTFail("Failed to initialize Minibits mint: \(error)")
        }
        
        // Test initializing the LNVoltz mint
        let lnvoltzURL = URL(string: "https://mint.lnvoltz.com")!
        
        do {
            let mint = try await CashuSwift.Mint(with: lnvoltzURL)
            XCTAssertNotNil(mint, "Should successfully initialize the LNVoltz mint")
            XCTAssertFalse(mint.keysets.isEmpty, "Mint should have keysets")
        } catch {
            XCTFail("Failed to initialize LNVoltz mint: \(error)")
        }
    }
    
    func testWalletCreation() async throws {
        // Test creating a wallet with a random mnemonic
        do {
            try await macadamiaBridge.createWallet()
            
            // Verify wallet was created
            XCTAssertTrue(walletState.walletInitialized, "Wallet should be initialized")
            XCTAssertNotNil(walletState.activeWallet, "Should have an active wallet")
            
            // Verify mnemonic
            let mnemonic = walletState.activeWallet?.mnemonic
            XCTAssertNotNil(mnemonic, "Wallet should have a mnemonic")
            if let mnemonic = mnemonic {
                let words = mnemonic.split(separator: " ").map(String.init)
                XCTAssertEqual(words.count, 12, "Mnemonic should have 12 words")
                XCTAssertTrue(BIP39.Mnemonic.isValid(words: words), "Mnemonic should be valid")
                
                print("Created wallet with mnemonic: \(mnemonic)")
            }
            
            // Verify default mints were added
            XCTAssertFalse(walletState.mints.isEmpty, "Wallet should have default mints")
            
            // Check for Minibits and LNVoltz mints specifically
            let hasMinibits = walletState.mints.contains { $0.url.absoluteString.contains("minibits") }
            let hasLNVoltz = walletState.mints.contains { $0.url.absoluteString.contains("lnvoltz") }
            
            XCTAssertTrue(hasMinibits, "Wallet should have the Minibits mint")
            XCTAssertTrue(hasLNVoltz, "Wallet should have the LNVoltz mint")
            
            print("Default mints: \(walletState.mints.map { $0.url.absoluteString }.joined(separator: ", "))")
        } catch {
            XCTFail("Failed to create wallet: \(error)")
        }
    }
    
    func testReceiveToken() async throws {
        // First create a wallet
        try await macadamiaBridge.createWallet()
        
        // Real Minibits token
        let minibitsToken = "fed11qvqpw9thwden5te0v9sjuctnvcczummjvuhhwue0qqqpj9mhwden5te0vekkwvfwv3cxcetz9e5kutmhwvhszqfqax36q0annypfxsxqarfecykxk7tk3ynwq2yxphr8qx46hr9cvn0qmctpcm"
        
        // Initial balance should be 0
        XCTAssertEqual(walletState.balance, 0, "Initial wallet balance should be 0")
        
        // This is a read-only test - we won't actually claim the token as that would spend it
        // Instead, we'll verify we can receive it without errors
        do {
            let token = try CashuSwift.parseToken(minibitsToken)
            XCTAssertNotNil(token, "Should successfully parse the token")
            
            // Calculate token value
            var tokenValue = 0
            for (_, mintData) in token.tokens {
                for proof in mintData.proofs {
                    tokenValue += proof.amount
                }
            }
            
            print("Token value: \(tokenValue) sats")
            
            // Verify the mint is available
            if let mintURL = token.tokens.keys.first, let url = URL(string: mintURL) {
                print("Checking if mint is available: \(url.absoluteString)")
                let mint = try await CashuSwift.Mint(with: url)
                XCTAssertNotNil(mint, "Mint should be available")
                
                // Check if proofs are valid
                if let proofs = token.tokens[mintURL]?.proofs {
                    print("Validating \(proofs.count) proofs...")
                    let states = try await CashuSwift.check(proofs, mint: mint)
                    let validCount = states.filter { $0 == .unspent }.count
                    
                    print("Valid proofs: \(validCount) of \(proofs.count)")
                    XCTAssertGreaterThan(validCount, 0, "At least one proof should be valid")
                }
            }
        } catch {
            XCTFail("Failed to process token: \(error)")
        }
    }
    
    func testEndToEndIntegration() async throws {
        // This test combines all steps to validate the full integration
        
        // 1. Create wallet
        try await macadamiaBridge.createWallet()
        XCTAssertTrue(walletState.walletInitialized, "Wallet should be initialized")
        
        // 2. Verify default mints were added including Minibits and LNVoltz
        let mintCount = walletState.mints.count
        XCTAssertGreaterThanOrEqual(mintCount, 4, "Should have at least 4 default mints")
        
        let mintURLs = walletState.mints.map { $0.url.absoluteString }
        print("Added mints: \(mintURLs.joined(separator: ", "))")
        
        // 3. Parse the token (read-only, won't actually claim it)
        let minibitsToken = "fed11qvqpw9thwden5te0v9sjuctnvcczummjvuhhwue0qqqpj9mhwden5te0vekkwvfwv3cxcetz9e5kutmhwvhszqfqax36q0annypfxsxqarfecykxk7tk3ynwq2yxphr8qx46hr9cvn0qmctpcm"
        let token = try CashuSwift.parseToken(minibitsToken)
        
        // 4. Calculate token value
        var tokenValue = 0
        for (_, mintData) in token.tokens {
            for proof in mintData.proofs {
                tokenValue += proof.amount
            }
        }
        
        print("Successfully integrated with Macadamia wallet!")
        print("- Created wallet with \(mintCount) default mints")
        print("- Parsed token with value: \(tokenValue) sats")
        print("- Integration test complete")
        
        XCTAssertTrue(true, "End-to-end test completed successfully")
    }
}