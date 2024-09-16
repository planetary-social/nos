import SwiftUI

extension View {
    func listRowGradientBackground() -> some View {
        modifier(ListRowGradientBackground())
    }
}

struct ListRowGradientBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .listRowBackground(LinearGradient(
                colors: [Color.cardBgTop, Color.cardBgBottom],
                startPoint: .top,
                endPoint: .bottom
            ))
    }
}
