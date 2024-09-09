import SwiftUI

/// A view that displays one or more lines of read-only text presented as a title.
///
///
/// This View was implemented to be re-used in the wizards that set-up and delete usernames in EditProfile screen.
struct WizardSheetTitleText: View {
    
    private var localizedStringResource: LocalizedStringResource

    init(_ localizedStringResource: LocalizedStringResource) {
        self.localizedStringResource = localizedStringResource
    }

    var body: some View {
        Text(localizedStringResource)
            .font(.clarityBold(.title))
            .foregroundStyle(Color.primaryTxt)
    }
}

#Preview {
    VStack(spacing: 10) {
        WizardSheetTitleText(LocalizedStringResource(stringLiteral: "Hello"))
    }
}
