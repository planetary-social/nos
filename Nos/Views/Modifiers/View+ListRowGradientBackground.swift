import SwiftUI

extension View {
    /// Applies a gradient background to list rows.
    func listRowGradientBackground() -> some View {
        modifier(ListRowGradientBackground())
    }
}

/// A gradient background to apply to list rows.
fileprivate struct ListRowGradientBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .listRowBackground(LinearGradient(
                colors: [Color.cardBgTop, Color.cardBgBottom],
                startPoint: .top,
                endPoint: .bottom
            ))
    }
}
