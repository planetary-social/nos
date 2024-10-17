import SwiftUI

struct ClaimYourUniqueIdentitySheet: View {

    @Binding var isPresented: Bool

    var body: some View {
        WizardSheetVStack {
            Spacer(minLength: 40)
            WizardSheetBadgeText("new")
            WizardSheetTitleText("claimUniqueUsernameTitle")
            WizardSheetDescriptionText(markdown: AttributedString(localized: "claimUniqueUsernameDescription"))
            Spacer(minLength: 0)
            NavigationLink("setUpMyUsername") {
                PickYourUsernameSheet(isPresented: $isPresented)
            }
            .buttonStyle(BigActionButtonStyle())
            NavigationLink {
                AlreadyHaveANIP05View(isPresented: $isPresented)
            } label: {
                Text("alreadyHaveANIP05")
                    .font(.clarity(.medium, textStyle: .subheadline))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            
            Spacer(minLength: 20)
        }
    }
}

#Preview {
    Color.clear.sheet(isPresented: .constant(true)) {
        ClaimYourUniqueIdentitySheet(isPresented: .constant(true))
            .presentationDetents([.medium])
    }
}
