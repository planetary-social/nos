import SwiftUI

struct NosToggle: View {
    @Binding var isOn: Bool
    var labelText: LocalizedStringResource

    var body: some View {
        Toggle(isOn: $isOn) {
            Text(labelText)
                .foregroundColor(.primaryTxt)
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
