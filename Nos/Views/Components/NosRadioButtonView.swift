import SwiftUI
/// A view that represents a radio button.
struct NosRadioButtonView: View {
    var isSelected: Bool
    var body: some View {
        ZStack {
            RadioButtonBackgroundView()
            if isSelected {
                RadioButtonSelectorView()
            }
        }
    }
}

struct RadioButtonBackgroundView: View {
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

struct RadioButtonSelectorView: View {
    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [Color.radioButtonSelectorTop, Color.radioButtonSelectorBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 17, height: 17)
    }
}

#Preview {
    NosRadioButtonView(isSelected: true)
        .previewDisplayName("Selected")
}

#Preview {
    NosRadioButtonView(isSelected: false)
        .previewDisplayName("Not Selected")
}
