import Dependencies
import SwiftUI

/// The Public Key view in the onboarding.
struct PublicKeyView: View {
    @Environment(OnboardingState.self) private var state
    @Environment(CurrentUser.self) var currentUser

    @State private var publicKeyString = ""
    @State private var copyButtonState: CopyButtonState = .copy

    var body: some View {
        ZStack {
            Color.appBg
                .ignoresSafeArea()
            ViewThatFits(in: .vertical) {
                publicKeyStack

                ScrollView {
                    publicKeyStack
                }
            }
            .onAppear {
                publicKeyString = currentUser.keyPair?.npub ?? ""
            }
        }
        .navigationBarHidden(true)
    }

    var publicKeyStack: some View {
        VStack(alignment: .leading, spacing: 20) {
            LargeNumberView(2)
            HStack(alignment: .firstTextBaseline) {
                Text("publicKeyHeadline")
                    .font(.clarityBold(.title))
                    .foregroundStyle(Color.primaryTxt)
                Text("publicKeyNpubParenthetical")
                    .font(.clarityRegular(.title2))
                    .foregroundStyle(Color.secondaryTxt)
            }
            Text("publicKeyDescription")
                .font(.body)
                .foregroundStyle(Color.secondaryTxt)
            CopyKeyView("copyPublicKey", keyString: $publicKeyString, copyButtonState: $copyButtonState)
            Spacer()
            BigActionButton("next") {
                state.step = .displayName
            }
        }
        .padding(40)
        .readabilityPadding()
    }
}

#Preview {
    PublicKeyView()
        .environment(OnboardingState())
        .inject(previewData: PreviewData())
}
