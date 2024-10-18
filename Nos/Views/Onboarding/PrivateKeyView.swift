import Dependencies
import SwiftUI

/// The Private Key view in the onboarding.
struct PrivateKeyView: View {
    @Environment(OnboardingState.self) private var state
    @Environment(CurrentUser.self) var currentUser

    @State private var privateKeyString = ""
    @State private var copyButtonState: CopyButtonState = .copy

    var body: some View {
        ZStack {
            Color.appBg
                .ignoresSafeArea()
            ViewThatFits(in: .vertical) {
                privateKeyStack

                ScrollView {
                    privateKeyStack
                }
            }
            .onAppear {
                privateKeyString = currentUser.keyPair?.nsec ?? ""
            }
        }
        .navigationBarHidden(true)
    }

    var privateKeyStack: some View {
        VStack(alignment: .leading, spacing: 20) {
            LargeNumberView(1)
            HStack(alignment: .firstTextBaseline) {
                Text("privateKeyHeadline")
                    .font(.clarityBold(.title))
                    .foregroundStyle(Color.primaryTxt)
                Text("privateKeyNsecParenthetical")
                    .font(.clarityRegular(.title2))
                    .foregroundStyle(Color.secondaryTxt)
            }
            PrivateKeyDescription()
            BorderedPrivateKey(privateKeyString: $privateKeyString, copyButtonState: $copyButtonState)
            Spacer()
            BigActionButton("next") {
                state.step = .buildYourNetwork
            }
        }
        .padding(40)
        .readabilityPadding()
    }
}

fileprivate enum CopyButtonState {
    case copy
    case copied
}

fileprivate struct PrivateKeyDescription: View {
    var body: some View {
        let attributedString = AttributedString(localized: "privateKeyDescription")
            .replacingAttributes(
                AttributeContainer(
                    [.inlinePresentationIntent: InlinePresentationIntent.stronglyEmphasized.rawValue]
                ),
                with: AttributeContainer([
                    .inlinePresentationIntent: InlinePresentationIntent.stronglyEmphasized.rawValue,
                    .foregroundColor: UIColor(.primaryTxt)
                ])
            )
        return Text(attributedString)
            .font(.body)
            .foregroundStyle(Color.secondaryTxt)
    }
}

fileprivate struct BorderedPrivateKey: View {
    @Binding var privateKeyString: String
    @Binding var copyButtonState: CopyButtonState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(privateKeyString)
            HStack {
                if copyButtonState == .copy {
                    Image.copyIcon
                        .frame(width: 20, height: 20)
                } else {
                    Image(systemName: "checkmark")
                        .frame(width: 20, height: 20)
                }
                Button {
                    UIPasteboard.general.string = privateKeyString
                    copyButtonState = .copied
                    Task { @MainActor in
                        try await Task.sleep(for: .seconds(10))
                        copyButtonState = .copy
                    }
                } label: {
                    Text(copyButtonState == .copy ? "copyPrivateKey" : "copied")
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
    PrivateKeyView()
        .environment(OnboardingState())
        .inject(previewData: PreviewData())
}
