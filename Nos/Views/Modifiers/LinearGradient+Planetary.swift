import SwiftUI

extension LinearGradient {
    
    public static let horizontalAccent = LinearGradient(
        colors: [ Color(hex: "#F08508"), Color(hex: "#F43F75")],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    public static let diagonalAccent = LinearGradient(
        colors: [ Color(hex: "#F08508"), Color(hex: "#F43F75")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
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
    
    public static let cardGradient = LinearGradient(
        colors: [Color.cardBgTop, Color.cardBgBottom],
        startPoint: .top,
        endPoint: .bottom
    )

    public static let cardBackground = LinearGradient(
        colors: [.cardBgTop, .cardBgBottom],
        startPoint: .top,
        endPoint: .bottom
    )

    public static let storiesBackground = LinearGradient(
        colors: [.storiesBgTop, .storiesBgBottom],
        startPoint: .top,
        endPoint: .bottom
    )
    
    public static let gold = LinearGradient(
        colors: [Color(hex: "#FFC46B"), Color(hex: "#DE7C21")],
        startPoint: .top,
        endPoint: .bottom
    )

    public static let nip05 = LinearGradient(
        colors: [Color.nip05BgGradientTop, Color.nip05BgGradientBottom],
        startPoint: .top,
        endPoint: .bottom
    )
}
