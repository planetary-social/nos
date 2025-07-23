// ABOUTME: Default recommended Cashu mints for new users
// ABOUTME: Provides curated list of trusted mints with metadata

import Foundation

/// Information about a Cashu mint
public struct MintInfo {
    let name: String
    let url: String
    let description: String
    let isRecommended: Bool
    let supportedCurrencies: [String]
    let lightningGateway: String? // URL for Lightning -> Cashu conversions
}

/// Default mints configuration
public struct DefaultMints {
    
    /// List of recommended mints for new users
    public static let recommended: [MintInfo] = [
        MintInfo(
            name: "Minibits",
            url: "https://mint.minibits.cash/Bitcoin",
            description: "Popular Cashu mint with good uptime and Lightning integration",
            isRecommended: true,
            supportedCurrencies: ["BTC"],
            lightningGateway: "https://mint.minibits.cash"
        ),
        MintInfo(
            name: "LNbits Legend",
            url: "https://legend.lnbits.com/cashu/api/v1/4gr9Xcmz3XEkUNwiBiQGoC",
            description: "Community mint powered by LNbits",
            isRecommended: true,
            supportedCurrencies: ["BTC"],
            lightningGateway: "https://legend.lnbits.com"
        ),
        MintInfo(
            name: "8333.space",
            url: "https://8333.space:3338",
            description: "Privacy-focused Cashu mint",
            isRecommended: true,
            supportedCurrencies: ["BTC"],
            lightningGateway: nil
        )
    ]
    
    /// Additional mints that users might want to add
    public static let additional: [MintInfo] = [
        MintInfo(
            name: "Nutstash",
            url: "https://mint.nutstash.app",
            description: "Cashu mint with web wallet interface",
            isRecommended: false,
            supportedCurrencies: ["BTC"],
            lightningGateway: "https://mint.nutstash.app"
        ),
        MintInfo(
            name: "Cashu.me",
            url: "https://8333.space:3338",
            description: "Easy-to-use Cashu mint",
            isRecommended: false,
            supportedCurrencies: ["BTC"],
            lightningGateway: nil
        )
    ]
    
    /// Get all available mints
    public static var all: [MintInfo] {
        recommended + additional
    }
    
    /// Find a mint by URL
    public static func mintInfo(for url: String) -> MintInfo? {
        all.first { $0.url == url }
    }
    
    /// Default mint for new wallets
    public static var defaultMint: MintInfo {
        recommended.first!
    }
    
    /// Check if a mint URL is in our known list
    public static func isKnownMint(_ url: String) -> Bool {
        all.contains { $0.url == url }
    }
    
    /// Get Lightning gateway for a mint (if available)
    public static func lightningGateway(for mintURL: String) -> String? {
        mintInfo(for: mintURL)?.lightningGateway
    }
}