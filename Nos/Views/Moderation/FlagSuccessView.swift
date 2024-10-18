import SwiftUI

/// Shows a success message after the user has successfully flagged a user or content
struct FlagSuccessView: View {
    var body: some View {
        VStack(spacing: 30) {
            Image.circularCheckmark
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 116)

            Text("thanksForTag")
                .foregroundColor(.primaryTxt)
                .font(.title2)
                .padding(.horizontal, 25)

            Text("keepOnHelpingUs")
                .padding(.horizontal, 25)
                .foregroundColor(.secondaryTxt)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .font(.body)
        }
    }
}

#Preview {
    FlagSuccessView()
}
