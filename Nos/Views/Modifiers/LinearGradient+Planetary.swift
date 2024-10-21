import SwiftUI

extension LinearGradient {
    
    public static let horizontalAccent = LinearGradient(
        colors: [.actionPrimaryGradientTop, .actionPrimaryGradientBottom],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    public static let horizontalAccentReversed = LinearGradient(
        colors: [.actionPrimaryGradientBottom, .actionPrimaryGradientTop],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    public static let diagonalAccent = LinearGradient(
        colors: [.actionPrimaryGradientTop, .actionPrimaryGradientBottom],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let diagonalAccent2 = LinearGradient(
        colors: [.actionPrimaryGradientTop, .actionPrimaryGradientBottom],
        startPoint: .bottomLeading,
        endPoint: .topTrailing
    )
    
    public static let verticalAccentPrimary = LinearGradient(
        colors: [.actionPrimaryGradientTop, .actionPrimaryGradientBottom],
        startPoint: .top,
        endPoint: .bottom
    )
    
    public static let verticalAccentSecondary = LinearGradient(
        colors: [.actionSecondaryGradientTop, .actionSecondaryGradientBottom],
        startPoint: .top,
        endPoint: .bottom
    )

    public static let brokenLinkBackground = LinearGradient(
        colors: [.brokenLinkBackgroundTop, .brokenLinkBackgroundBottom],
        startPoint: .top,
        endPoint: .bottom
    )

    public static let cardGradient = LinearGradient(
        colors: [.cardBgTop, .cardBgBottom],
        startPoint: .top,
        endPoint: .bottom
    )

    public static let cardBackground = LinearGradient(
        colors: [.cardBgTop, .cardBgBottom],
        startPoint: .top,
        endPoint: .bottom
    )

    public static let gold = LinearGradient(
        colors: [.goldBgGradientTop, .goldBgGradientBottom],
        startPoint: .top,
        endPoint: .bottom
    )

    public static let nip05 = LinearGradient(
        colors: [.nip05BgGradientTop, .nip05BgGradientBottom],
        startPoint: .top,
        endPoint: .bottom
    )

    public static let bio = LinearGradient(
        colors: [.bioBgGradientTop, .bioBgGradientBottom],
        startPoint: .top,
        endPoint: .bottom
    )
}
