import Dependencies
import SwiftUI

/// The Create Account view in the onboarding.
struct CreateAccountView: View {
    @Environment(OnboardingState.self) private var state

    @Dependency(\.crashReporting) private var crashReporting
    @Dependency(\.currentUser) private var currentUser

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("👋")
                .font(.system(size: 60))
            Text("createAccountHeadline")
                .font(.clarityBold(.title))
                .foregroundStyle(Color.primaryTxt)
            Text("createAccountDescription")
                .foregroundStyle(Color.secondaryTxt)
            Spacer()
            NumberedStepsView()
                .padding(.horizontal, 10)
            Spacer()
            BigActionButton(title: "createAccountButton") {
                do {
                    try await currentUser.createAccount()
                } catch {
                    crashReporting.report(error)
                }
                state.step = .buildYourNetwork
            }
        }
        .padding(40)
        .background(Color.appBg)
        .navigationBarHidden(true)
    }
}

/// The four numbered steps with their corresponding text.
fileprivate struct NumberedStepsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 50) {
            NumberedStepView(index: 1, label: "createAccountPrivateKey")
            NumberedStepView(index: 2, label: "createAccountPublicKey")
            NumberedStepView(index: 3, label: "createAccountDisplayName")
            NumberedStepView(index: 4, label: "createAccountUsername")
        }
        .background(
            ConnectingLine()
                .offset(x: 5)
                .stroke(Color.profileDividerShadow, lineWidth: 4),
            alignment: .leading
        )
    }
}

/// A view containing an index with a circle background and some text.
fileprivate struct NumberedStepView: View {
    let index: Int
    let label: LocalizedStringKey

    var body: some View {
        HStack(alignment: .center, spacing: 20) {
            Text(index, format: .number)
                .font(.clarityBold(.headline))
                .foregroundStyle(Color.primaryTxt)
                .background(
                    Circle()
                        .fill(Color.profileDividerShadow)
                        .frame(width: 30, height: 30)
                )

            Text(label)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(Color.primaryTxt)
        }
    }
}

/// Custom shape for the vertical connecting line
fileprivate struct ConnectingLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let startPoint = CGPoint(x: rect.minX, y: 0)
        let endPoint = CGPoint(x: rect.minX, y: rect.maxY)

        path.move(to: startPoint)
        path.addLine(to: endPoint)

        return path
    }
}

#Preview {
    CreateAccountView()
        .environment(OnboardingState())
}
