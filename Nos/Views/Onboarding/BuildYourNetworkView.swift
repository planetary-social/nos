import SwiftUI

/// The Build Your Network view in the onboarding.
struct BuildYourNetworkView: View {
    /// The action to perform when the user taps the Find people button.
    let completion: @MainActor () -> Void
    
    /// The padding around most of the views here -- the text and button -- but not the image.
    private let padding: CGFloat = 40

    var body: some View {
        ZStack {
            Color.appBg
                .ignoresSafeArea()
            ViewThatFits(in: .vertical) {
                buildYourNetworkStack

                ScrollView {
                    buildYourNetworkStack
                }
            }
        }
        .navigationBarHidden(true)
    }

    private var buildYourNetworkStack: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("🔍")
                .font(.system(size: 60))
            Text("buildYourNetwork")
                .font(.clarityBold(.title))
                .foregroundStyle(Color.primaryTxt)
                .fixedSize(horizontal: false, vertical: true)
            Text("buildYourNetworkDescription")
                .foregroundStyle(Color.secondaryTxt)
                .fixedSize(horizontal: false, vertical: true)
            Image.network
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(.horizontal, -padding)
            Spacer()
            BigActionButton("findPeople") { @MainActor in
                completion()
            }
        }
        .padding(padding)
        .readabilityPadding()
    }
}

#Preview {
    BuildYourNetworkView {}
}
