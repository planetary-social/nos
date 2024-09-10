import SwiftUI
/// A toggle with the tint color set to green.
struct NosToggle: View {
    @Binding var isOn: Bool
    /// A string that shows up beside the toggle. Optional.
    var labelText: LocalizedStringResource?

    var body: some View {
        Toggle(isOn: $isOn) {
            if let labelText = labelText {
                Text(labelText)
                    .foregroundColor(.primaryTxt)
            }
        }
        .tint(.green)
    }
}

#Preview {
    @State var isOn = true

    return NosToggle(
        isOn: $isOn,
        labelText: .localizable.useReportsFromFollows
    )
}
