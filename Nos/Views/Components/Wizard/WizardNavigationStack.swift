import SwiftUI

/// A view that displays a root view and enables you to present additional views over the root view meant to be
/// presented modally in half-screen.
///
/// This Wizard Navigation Stack was implemented to be re-used in the wizards that set-up and delete usernames in
/// EditProfile screen.
struct WizardNavigationStack<Root>: View where Root: View {

    private let root: () -> Root

    init(@ViewBuilder root: @escaping () -> Root) {
        self.root = root
    }

    var body: some View {
        NavigationStack(root: root)
            .frame(idealWidth: 320, idealHeight: 480)
            .presentationDetents([.height(480)])
    }
}

#Preview {
    Color.clear.sheet(isPresented: .constant(true)) {
        WizardNavigationStack {
            Text("Hello")
        }
    }
}
