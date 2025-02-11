import Foundation
import SwiftUI

extension View {
    /// Applies a rounded border with a subtle styled gradient to this view.
    func withStyledBorder() -> some View {
        modifier(StyledBorder())
    }
}

/// A rounded border with a subtle styled gradient.
fileprivate struct StyledBorder: ViewModifier {
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                .styledBorderGradientTop,
                                .styledBorderGradientBottom
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 3
                    )
            )
            .shadow(
                color: .styledBorderShadow,
                radius: 2,
                x: 0,
                y: 2
            )
    }
}
