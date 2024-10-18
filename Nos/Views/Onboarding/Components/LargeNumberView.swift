import SwiftUI

/// A view that displays a large number, used at the top of several onboarding screens.
struct LargeNumberView: View {
    let number: Int

    init(_ number: Int) {
        self.number = number
    }

    var body: some View {
        Text(number, format: .number)
            .font(.clarity(.bold, size: 40, textStyle: .largeTitle))
            .foregroundStyle(Color.primaryTxt)
            .frame(width: 60, height: 60)
            .background(
                Circle()
                    .fill(Color.numberedStepBackground)
            )
    }
}

#Preview {
    LargeNumberView(2)
}
