import SwiftUI

/// A  custom radio button.
struct NosRadioButton: View {
    var isSelected: Bool
    var body: some View {
        ZStack {
            RadioButtonBackground()
            if isSelected {
                RadioButtonSelectedIndicator()
            }
        }
    }
}

/// A custom background for a radio button.
private struct RadioButtonBackground: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.radioButtonBgTop, Color.radioButtonBgBottom],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 25, height: 25)
            // Inner shadow effect
                .overlay(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.radioButtonBgTop, Color.radioButtonBgBottom],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .stroke(Color.radioButtonInnerDropShadow, lineWidth: 1)
                        .blur(radius: 1.67)
                        .offset(x: 0, y: 0.67)
                        .mask(Circle()) // Ensures the inner shadow stays within the circle's shape
                )

            // Outer shadow effect
                .shadow(color: Color.radioButtonOuterDropShadow, radius: 0, x: 0, y: 0.99)
        }
    }
}

/// A colorful selector (inner circle) of a radio button with a gradient fill.
private struct RadioButtonSelectedIndicator: View {
    var body: some View {
        Circle()
            .fill(LinearGradient.verticalAccentPrimary)
            .frame(width: 17, height: 17)
    }
}

#Preview("Selected") {
    NosRadioButton(isSelected: true)
}

#Preview("Not Selected") {
    NosRadioButton(isSelected: false)
}
