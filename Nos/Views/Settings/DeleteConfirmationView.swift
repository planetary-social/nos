import SwiftUI

/// This view displays a title and message, along with a text field
/// for user confirmation. It provides buttons to cancel the action
/// or proceed with the deletion (which is enabled only when the
/// correct confirmation text is entered).
/// - Parameters:
///   - requiredText: The text that must be entered to confirm the deletion.
///   - onDelete: A closure that is called when the delete button is confirmed.
///   - onCancel: A closure that is called when the cancel button is selected.
struct DeleteConfirmationView: View {
    @State private var confirmationText: String = ""

    var requiredText: String
    var onDelete: (() -> Void)
    var onCancel: (() -> Void)

    var isDeleteDisabled: Bool {
        confirmationText != requiredText
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                titleMessageView()

                confirmationTextField(
                    confirmationText: $confirmationText,
                    requiredText: requiredText
                )
            }
            .padding()

            Divider()
                .frame(height: 1)
                .background(Color.actionSheetDivider)

            actionButtonsView(
                isDeleteDisabled: isDeleteDisabled, 
                onDelete: onDelete,
                onCancel: onCancel
            )
        }
        .background(Color.actionSheetBg)
        .cornerRadius(10)
        .frame(width: 302, height: 228)
        .shadow(color: Color.black.opacity(0.25), radius: 25, x: 0, y: 10)
    }

    /// Creates the title and message view for the delete confirmation.
    private func titleMessageView() -> some View {
        VStack(spacing: 0) {
            Text("deleteAccount")
                .font(.headline)
                .fontWeight(.bold)
                .padding(.bottom, 10)
                .padding(.top, 18)

            Text("deleteAccountMessage")
                .font(.footnote)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .padding(.horizontal)
                .padding(.bottom, 15)
        }
    }

    /// Creates the text field to confirm the user's input.
    /// - Parameters:
    ///   - confirmationText: A binding to the user's input text.
    ///   - requiredText: The text that must be entered for confirmation.
    /// - Returns: A `TextField` configured for confirming user's input.
    private func confirmationTextField(confirmationText: Binding<String>, requiredText: String) -> some View {
        let isTyping = !confirmationText.wrappedValue.isEmpty

        return TextField("", text: confirmationText)
            .foregroundColor(.white)
            .autocapitalization(.allCharacters)
            .padding(10)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(isTyping ? .white : Color.actionSheetTextfieldPlaceholder, lineWidth: 1)
            )
            .modifier(
                PlaceholderStyle(
                    show: confirmationText.wrappedValue.isEmpty,
                    placeholder: String(localized: "typeDelete")
                )
            )
            .background(isTyping ? Color.actionSheetTextfieldBgBright : Color.actionSheetTextfieldBgDim)
            .padding(.horizontal, 22)
            .padding(.bottom, 5)
    }

    /// Creates the cancel and delete buttons.
    private func actionButtonsView(
        isDeleteDisabled: Bool,
        onDelete: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) -> some View {
        HStack {
            Button("cancel") {
                onCancel()
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(.blue)

            Divider()
                .frame(width: 1, height: 50)
                .background(Color.actionSheetDivider)

            Button("delete") {
                onDelete()
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(isDeleteDisabled ? Color.actionSheetDivider : .red)
            .disabled(isDeleteDisabled)
        }
    }
}

#Preview {
    DeleteConfirmationView(
        requiredText: String(localized: "deleteAccount").uppercased(),
        onDelete: {},
        onCancel: {}
    )
}
