// ABOUTME: Tests for CashuWallet functionality including initialization and basic operations
// ABOUTME: Covers NIP-60 wallet data storage and NIP-61 nutzap creation

import XCTest
import CashuSwift
@testable import Nos

final class CashuWalletTests: XCTestCase {
    
    func testInitializeCashuWallet() throws {
        // Given
        let walletName = "Test Wallet"
        let mintURLString = "https://mint.minibits.cash/Bitcoin"
        
        // When
        let wallet = CashuWallet(name: walletName, mintURL: mintURLString)
        
        // Then
        XCTAssertNotNil(wallet)
        XCTAssertEqual(wallet.name, walletName)
        XCTAssertEqual(wallet.mintURL, mintURLString)
        XCTAssertNotNil(wallet.walletPrivateKey)
        XCTAssertNotNil(wallet.walletPublicKey)
        XCTAssertNotEqual(wallet.walletPrivateKey, "")
        XCTAssertNotEqual(wallet.walletPublicKey, "")
    }
    
    func testWalletGeneratesDifferentKeysEachTime() throws {
        // Given
        let wallet1 = CashuWallet(name: "Wallet 1", mintURL: "https://mint.minibits.cash/Bitcoin")
        let wallet2 = CashuWallet(name: "Wallet 2", mintURL: "https://mint.minibits.cash/Bitcoin")
        
        // Then
        XCTAssertNotEqual(wallet1.walletPrivateKey, wallet2.walletPrivateKey)
        XCTAssertNotEqual(wallet1.walletPublicKey, wallet2.walletPublicKey)
    }
    
    func testWalletSupportsMultipleMints() throws {
        // Given
        let primaryMint = "https://mint.minibits.cash/Bitcoin"
        let secondaryMint = "https://legend.lnbits.com/cashu/api/v1/4gr9Xcmz3XEkUNwiBiQGoC"
        
        // When
        let wallet = CashuWallet(name: "Multi-mint Wallet", mintURL: primaryMint)
        wallet.addMint(secondaryMint)
        
        // Then
        XCTAssertEqual(wallet.trustedMints.count, 2)
        XCTAssertTrue(wallet.trustedMints.contains(primaryMint))
        XCTAssertTrue(wallet.trustedMints.contains(secondaryMint))
    }
}