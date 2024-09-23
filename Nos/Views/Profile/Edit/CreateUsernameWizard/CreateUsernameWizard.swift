import Dependencies
import SwiftUI

struct CreateUsernameWizard: View {

    @Binding var isPresented: Bool

    @Dependency(\.analytics) private var analytics

    var body: some View {
        WizardNavigationStack {
            ClaimYourUniqueIdentitySheet(isPresented: $isPresented)
        }
        .onAppear {
            analytics.showedNIP05Wizard()
        }
    }
}

#Preview {
    Color.clear.sheet(isPresented: .constant(true)) {
        CreateUsernameWizard(isPresented: .constant(true))
    }
}
