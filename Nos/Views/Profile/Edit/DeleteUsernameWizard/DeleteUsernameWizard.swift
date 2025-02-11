import SwiftUI

struct DeleteUsernameWizard: View {

    let author: Author
    @Binding var isPresented: Bool

    var body: some View {
        WizardNavigationStack {
            ConfirmUsernameDeletionSheet(
                author: author,
                isPresented: $isPresented
            )
        }
    }
}

#Preview {
    var previewData = PreviewData()
    return Color.clear.sheet(isPresented: .constant(true)) {
        DeleteUsernameWizard(
            author: previewData.alice,
            isPresented: .constant(true)
        )
    }
    .inject(previewData: previewData)
}
