import SwiftUI

/// A view that displays one or more lines of read-only text presented as a badge.
///
///
/// This Text was implemented to be re-used in the wizards that set-up and delete usernames in EditProfile screen.
struct WizardSheetBadgeText: View {

    private var localizedStringKey: LocalizedStringKey

    init(_ localizedStringKey: LocalizedStringKey) {
        self.localizedStringKey = localizedStringKey
    }

    var body: some View {
        Text(localizedStringKey)
            .textCase(.uppercase)
            .padding(.horizontal, 6)
            .padding(.vertical, 5)
            .font(.clarity(.bold, textStyle: .footnote))
            .foregroundStyle(Color.white)
            .background {
                Color.secondaryTxt
                    .cornerRadius(4, corners: .allCorners)
            }
    }
}

#Preview {
    WizardSheetBadgeText("Hello")
}
