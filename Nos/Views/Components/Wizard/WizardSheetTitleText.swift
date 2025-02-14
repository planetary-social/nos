import SwiftUI

/// A view that displays one or more lines of read-only text presented as a title.
///
///
/// This View was implemented to be re-used in the wizards that set-up and delete usernames in EditProfile screen.
struct WizardSheetTitleText: View {
    
    private let localizedStringKey: LocalizedStringKey

    init(_ localizedStringKey: LocalizedStringKey) {
        self.localizedStringKey = localizedStringKey
    }

    var body: some View {
        Text(localizedStringKey)
            .font(.clarityBold(.title))
            .foregroundStyle(Color.primaryTxt)
    }
}

#Preview {
    VStack(spacing: 10) {
        WizardSheetTitleText("Hello")
    }
}
