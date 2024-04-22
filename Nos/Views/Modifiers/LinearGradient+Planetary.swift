import SwiftUI

extension LinearGradient {
    
    public static let horizontalAccent = LinearGradient(
        colors: [ Color.actionPrimaryGradientTop, Color.actionPrimaryGradientBottom],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    public static let diagonalAccent = LinearGradient(
        colors: [ Color.actionPrimaryGradientTop, Color.actionPrimaryGradientBottom],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let diagonalAccent2 = LinearGradient(
        colors: [ Color.actionPrimaryGradientTop, Color.actionPrimaryGradientBottom],
        startPoint: .bottomLeading,
        endPoint: .topTrailing
    )
    
    public static let verticalAccent = LinearGradient(
        colors: [ Color.actionPrimaryGradientTop, Color.actionPrimaryGradientBottom],
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
