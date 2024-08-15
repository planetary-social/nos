import Foundation
import SwiftUI

extension View {
    func withStyledBorder() -> some View {
        modifier(StyledBorder())
    }
}

struct StyledBorder: ViewModifier {
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color("styled-border-gradient-top"),
                                Color("styled-border-gradient-bottom")
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 3
                    )
            )
            .shadow(
                color: Color(white: 0, opacity: 0.15),
                radius: 2,
                x: 0,
                y: 2
            )
    }
}
