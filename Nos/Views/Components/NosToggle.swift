import SwiftUI

/// A toggle with the tint color set to green.
struct NosToggle: View {
    /// A string that shows up beside the toggle. Optional.
    var labelText: LocalizedStringKey?
    
    @Binding var isOn: Bool

    init(_ labelText: LocalizedStringKey? = nil, isOn: Binding<Bool>) {
        self.labelText = labelText
        self._isOn = isOn
    }
    
    var body: some View {
        Toggle(isOn: $isOn) {
            if let labelText {
                Text(labelText)
                    .foregroundColor(.primaryTxt)
            }
        }
        .tint(.green) // Fixes [#1251](https://github.com/planetary-social/nos/issues/1251)
    }
}

#Preview {
    @Previewable @State var isOn = true

    return NosToggle(
        "useReportsFromFollows",
        isOn: $isOn
    )
}
