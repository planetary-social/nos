import SwiftUI

/// A bordered view that shows a key and a button to copy it. When the user taps the copy button,
/// its title changes to "Copied!".
struct CopyKeyView: View {
    let buttonTitle: LocalizedStringKey

    @Binding var keyString: String
    @Binding var copyButtonState: CopyButtonState

    init(_ buttonTitle: LocalizedStringKey, keyString: Binding<String>, copyButtonState: Binding<CopyButtonState>) {
        self.buttonTitle = buttonTitle
        _keyString = keyString
        _copyButtonState = copyButtonState
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(keyString)
            HStack {
                if copyButtonState == .copy {
                    Image.copyIcon
                        .frame(width: 20, height: 20)
                } else {
                    Image(systemName: "checkmark")
                        .frame(width: 20, height: 20)
                }
                Button {
                    UIPasteboard.general.string = keyString
                    copyButtonState = .copied
                    Task { @MainActor in
                        try await Task.sleep(for: .seconds(10))
                        copyButtonState = .copy
                    }
                } label: {
                    Text(copyButtonState == .copy ? buttonTitle : "copied")
                }
                Spacer()
            }
            .foregroundStyle(Color.actionTertiary)
        }
        .padding()
        .withStyledBorder()
    }
}

#Preview {
    @Previewable @State var privateKey = KeyFixture.nsec
    @Previewable @State var privateCopyButtonState = CopyButtonState.copy

    @Previewable @State var publicKey = KeyFixture.npub
    @Previewable @State var publicCopyButtonState = CopyButtonState.copied

    return VStack(spacing: 40) {
        CopyKeyView("copyPrivateKey", keyString: $privateKey, copyButtonState: $privateCopyButtonState)
        CopyKeyView("copyPublicKey", keyString: $publicKey, copyButtonState: $publicCopyButtonState)
    }
}

enum KeyType {
    case `public`
    case `private`
}
