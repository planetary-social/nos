import Dependencies
import SwiftUI

/// The Private Key view in the onboarding.
struct PrivateKeyView: View {
    @Environment(OnboardingState.self) private var state
    @Environment(CurrentUser.self) private var currentUser

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

    private var privateKeyStack: some View {
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
            CopyKeyView("copyPrivateKey", keyString: $privateKeyString, copyButtonState: $copyButtonState)
            Spacer()
            BigActionButton("next") {
                state.step = .publicKey
            }
        }
        .padding(40)
        .readabilityPadding()
    }
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

#Preview {
    PrivateKeyView()
        .environment(OnboardingState())
        .inject(previewData: PreviewData())
}
