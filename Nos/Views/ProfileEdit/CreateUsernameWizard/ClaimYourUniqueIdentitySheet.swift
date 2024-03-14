import SwiftUI

struct ClaimYourUniqueIdentitySheet: View {

    @Binding var isPresented: Bool

    var body: some View {
        WizardSheetVStack {
            Spacer(minLength: 40)
            WizardSheetBadgeText(.localizable.new)
            WizardSheetTitleText(.localizable.claimUniqueUsernameTitle)
            WizardSheetDescriptionText(markdown: .localizable.claimUniqueUsernameDescription)
            Spacer(minLength: 0)
            NavigationLink(String(localized: LocalizedStringResource.localizable.setUpMyUsername)) {
                PickYourUsernameSheet(isPresented: $isPresented)
            }
            .buttonStyle(BigActionButtonStyle())
            Spacer(minLength: 40)
        }
    }
}

#Preview {
    Color.clear.sheet(isPresented: .constant(true)) {
        ClaimYourUniqueIdentitySheet(isPresented: .constant(true))
            .presentationDetents([.medium])
    }
}
