import SwiftUI

/// The Build Your Network view in the onboarding.
struct BuildYourNetworkView: View {
    /// The action to perform when the user taps the Find people button.
    let completion: @MainActor () -> Void
    
    /// The padding around most of the views here -- the text and button -- but not the image.
    private let padding: CGFloat = 40

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 20) {
                Text("🔍")
                    .font(.system(size: 60))
                Text("buildYourNetwork")
                    .font(.clarityBold(.title))
                    .foregroundStyle(Color.primaryTxt)
                Text("buildYourNetworkDescription")
                    .foregroundStyle(Color.secondaryTxt)
                Image.network
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: geometry.size.width)
                    .offset(x: -padding)
                Spacer()
                BigActionButton("findPeople") {
                    completion()
                }
            }
            .padding(padding)
            .background(Color.appBg)
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    BuildYourNetworkView {}
}
