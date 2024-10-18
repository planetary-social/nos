import Dependencies
import SwiftUI

/// The Create Account view in the onboarding.
struct CreateAccountView: View {
    @Environment(OnboardingState.self) private var state
    @Environment(CurrentUser.self) var currentUser
    
    @Dependency(\.crashReporting) private var crashReporting

    var body: some View {
        ZStack {
            Color.appBg
                .ignoresSafeArea()
            ViewThatFits(in: .vertical) {
                createAccountStack

                ScrollView {
                    createAccountStack
                }
            }
        }
        .navigationBarHidden(true)
    }

    var createAccountStack: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("👋")
                .font(.system(size: 60))
            Text("createAccountHeadline")
                .font(.clarityBold(.title))
                .foregroundStyle(Color.primaryTxt)
            Text("createAccountDescription")
                .font(.body)
                .foregroundStyle(Color.secondaryTxt)
                .padding(.bottom, 10)
            NumberedStepsView()
                .padding(.horizontal, 10)
            Spacer()
            BigActionButton("createAccountButton") {
                do {
                    try await currentUser.createAccount()
                } catch {
                    crashReporting.report(error)
                }
                state.step = .privateKey
            }
        }
        .padding(40)
        .readabilityPadding()
    }
}

/// The four numbered steps with their corresponding text.
fileprivate struct NumberedStepsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 50) {
            NumberedStepView(index: 1, label: "privateKeyHeadline")
            NumberedStepView(index: 2, label: "publicKeyHeadline")
            NumberedStepView(index: 3, label: "displayNameHeadline")
            NumberedStepView(index: 4, label: "usernameHeadline")
        }
        .background(
            ConnectingLine()
                .offset(x: 8)
                .stroke(Color.numberedStepBackground, lineWidth: 4),
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
                .frame(width: 16)
                .background(
                    Circle()
                        .fill(Color.numberedStepBackground)
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
        .inject(previewData: PreviewData())
}
